module Config = struct
  type ca_certs =
    | Ca_cert of string
    | Ca_path of string
    | Detect

  type t =
    { username : string
    ; password : string
    ; hostname : string
    ; port : int option
    ; with_starttls : bool
    ; ca_certs : ca_certs
    }

  let make ~username ~password ~hostname ~with_starttls =
    { username; password; hostname; with_starttls; port = None; ca_certs = Detect }
  ;;

  let set_port port config = { config with port }
  let set_ca_cert path config = { config with ca_certs = Ca_cert path }
  let set_ca_path path config = { config with ca_certs = Ca_path path }
end

type body =
  | Plain of string
  | Html of string
  | Mixed of string * string * string option

type mt_body =
  | MtSimple of Mrmime.Mt.part
  | MtMultipart of Mrmime.Mt.multipart

type recipient =
  | To of string
  | Cc of string
  | Bcc of string

exception Invalid_email_address of string

let stream_of_string s =
  let once = ref false in
  fun () ->
    if !once
    then None
    else (
      once := true;
      Some (s, 0, String.length s))
;;

let str_to_colombe_address str_address =
  match Emile.of_string str_address with
  | Ok mailbox ->
    (match Colombe_emile.to_forward_path mailbox with
    | Ok address -> address
    | Error _ -> raise (Invalid_email_address str_address))
  | Error _ -> raise (Invalid_email_address str_address)
;;

let domain_of_reverse_path = function
  | None -> Rresult.R.error_msgf "reverse-path is empty"
  | Some { Colombe.Path.domain; _ } -> Ok domain
;;

let to_recipient_to_address : recipient -> Mrmime.Address.t option =
 fun recipient ->
  match recipient with
  | To address ->
    (match Mrmime.Mailbox.of_string address with
    | Ok mailbox -> Some (Mrmime.Address.mailbox mailbox)
    | Error _ -> raise (Invalid_email_address address))
  | Cc _ -> None
  | Bcc _ -> None
;;

let cc_recipient_to_address : recipient -> Mrmime.Address.t option =
 fun recipient ->
  match recipient with
  | To _ -> None
  | Cc address ->
    (match Mrmime.Mailbox.of_string address with
    | Ok mailbox -> Some (Mrmime.Address.mailbox mailbox)
    | Error _ -> raise (Invalid_email_address address))
  | Bcc _ -> None
;;

let now () = Some (Ptime_clock.now ())

let build_email ~from ~recipients ~subject ~body =
  try
    let open Mrmime in
    let subject = Unstructured.Craft.v subject in
    let date = Date.of_ptime ~zone:Date.Zone.GMT (Ptime_clock.now ()) in
    let from_addr =
      match Mailbox.of_string from with
      | Ok v -> v
      | Error _ -> raise (Invalid_email_address from)
    in
    let to_addresses = List.filter_map to_recipient_to_address recipients in
    let cc_addresses = List.filter_map cc_recipient_to_address recipients in
    let headers =
      [ Field.(Field (Field_name.subject, Unstructured, subject))
      ; Field.(Field (Field_name.date, Date, date))
      ; Field.(Field (Field_name.from, Mailbox, from_addr))
      ; Field.(Field (Field_name.v "To", Addresses, to_addresses))
      ; Field.(Field (Field_name.cc, Addresses, cc_addresses))
      ]
    in
    let plain_text_headers =
      let content1 =
        let open Content_type in
        make
          `Text
          (Subtype.v `Text "plain")
          Parameters.(of_list [ k "charset", v "utf-8" ])
      in
      Header.of_list
        Field.
          [ Field (Field_name.content_type, Content, content1)
          ; Field (Field_name.content_encoding, Encoding, `Quoted_printable)
          ]
    in
    let html_headers =
      let content1 =
        let open Content_type in
        make
          `Text
          (Subtype.v `Text "html")
          Parameters.(of_list [ k "charset", v "utf-8" ])
      in
      Header.of_list
        Field.
          [ Field (Field_name.content_type, Content, content1)
          ; Field (Field_name.content_encoding, Encoding, `Quoted_printable)
          ]
    in
    let body =
      let multipart_content_alternative =
        let open Content_type in
        make `Multipart (Subtype.v `Multipart "alternative") Parameters.empty
      in
      match body with
      | Plain text ->
        MtSimple (Mt.part ~header:plain_text_headers (stream_of_string text))
      | Html html -> MtSimple (Mt.part ~header:html_headers (stream_of_string html))
      | Mixed (text, html, boundary) ->
        let plain = Mt.part ~header:plain_text_headers (stream_of_string text) in
        let html = Mt.part ~header:html_headers (stream_of_string html) in
        let header =
          Header.of_list
            [ Field (Field_name.content_type, Content, multipart_content_alternative) ]
        in
        (match boundary with
        | None -> MtMultipart (Mt.multipart ~rng:Mt.rng ~header [ plain; html ])
        | Some boundary ->
          MtMultipart (Mt.multipart ~rng:Mt.rng ~header ~boundary [ plain; html ]))
    in
    match body with
    | MtSimple part -> Ok (Mt.make (Mrmime.Header.of_list headers) Mt.simple part)
    | MtMultipart multi -> Ok (Mt.make (Mrmime.Header.of_list headers) Mt.multi multi)
  with
  | Invalid_email_address address ->
    Error (Printf.sprintf "Invalid email address: %s" address)
  | ex -> Error (Printexc.to_string ex)
;;

let ca_cert_peer_verifier path =
  let ( let* ) = Lwt.bind in
  let* certs = X509_lwt.certs_of_pem path in
  Lwt.return (X509.Authenticator.chain_of_trust ~time:now certs)
;;

let ca_path_peer_verifier path =
  let ( let* ) = Lwt.bind in
  let* certs = X509_lwt.certs_of_pem_dir path in
  Lwt.return (X509.Authenticator.chain_of_trust ~time:now certs)
;;

let send ~config:c ~sender ~recipients ~message =
  let open Config in
  let ( let* ) = Lwt.bind in
  let authentication : Sendmail.authentication =
    { username = c.username; password = c.password; mechanism = Sendmail.PLAIN }
  in
  let port =
    match c.port, c.with_starttls with
    | None, true -> 587
    | None, false -> 465
    | Some v, _ -> v
  in
  let mail = Mrmime.Mt.to_stream message in
  let from_mailbox =
    match Emile.of_string sender with
    | Ok v -> v
    | Error (`Invalid (_, _)) -> failwith "Invalid sender address"
  in
  let from_addr =
    match Colombe_emile.to_reverse_path from_mailbox with
    | Ok v -> v
    | Error (`Msg msg) -> failwith msg
  in
  let recipients =
    List.map
      (fun recipient ->
        (match recipient with
        | To a -> a
        | Cc a -> a
        | Bcc a -> a)
        |> str_to_colombe_address)
      recipients
  in
  let domain =
    match domain_of_reverse_path from_addr with
    | Ok v -> v
    | Error _ -> failwith "Failed to extract domain of sender address"
  in
  let hostname =
    match Domain_name.of_string c.hostname with
    | Error _ -> failwith "Config hostname is not valid hostname"
    | Ok hostname ->
      (match Domain_name.host hostname with
      | Error _ -> failwith "Config hostname is not valid hostname"
      | Ok hostname -> hostname)
  in
  let* tls_peer_verifier =
    match c.ca_certs with
    | Ca_path path -> ca_path_peer_verifier path
    | Ca_cert path -> ca_cert_peer_verifier path
    | Detect ->
      let* cert = Ca_certs.detect () in
      (match cert with
      | Some (`Ca_file path) -> ca_cert_peer_verifier path
      | None -> failwith "Could not find CA certificate bundle")
  in
  if c.with_starttls
  then
    let* res =
      Sendmail_handler.run_with_starttls
        ~hostname
        ~port
        ~domain
        ~authentication
        ~tls_authenticator:tls_peer_verifier
        ~from:from_addr
        ~recipients
        ~mail
    in
    match res with
    | Ok () -> Lwt.return ()
    | Error err ->
      Lwt.fail_with
        (Fmt.str "Sending email failed, %a" Sendmail_with_starttls.pp_error err)
  else
    let* res =
      Sendmail_handler.run
        ~hostname
        ~port
        ~domain
        ~authentication
        ~tls_authenticator:tls_peer_verifier
        ~from:from_addr
        ~recipients
        ~mail
    in
    match res with
    | Ok () -> Lwt.return ()
    | Error err ->
      Lwt.fail_with (Fmt.str "Sending email failed, %a" Sendmail.pp_error err)
;;
