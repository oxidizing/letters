type config = {
    sender: string;
    username: string;
    password: string;
    hostname: string;
    port: int option;
    with_starttls: bool;
    ca_dir: string;
}

type body = Plain of string | Html of string

type recipient = To of string | Cc of string | Bcc of string

let stream_of_string s =
  let once = ref false in
  (fun () -> if !once then None else ( once := true ; Some (s, 0, String.length s)))

let str_to_colombe_address str_address = match Emile.of_string str_address with
  | Ok mailbox -> (match Colombe_emile.to_forward_path mailbox with
      | Ok address -> address
      | Error _ -> failwith (Printf.sprintf "Invalid email address: %s" str_address))
  | Error _ -> failwith (Printf.sprintf "Invalid email address: %s" str_address)

let domain_of_reverse_path = function
  | None -> Rresult.R.error_msgf "reverse-path is empty"
  | Some { Colombe.Path.domain= domain; _ } -> Ok domain

let to_recipient_to_address : recipient -> Mrmime.Address.t option = fun recipient -> match recipient with
  | To address -> (match Mrmime.Mailbox.of_string address with
      | Ok mailbox -> Some (Mrmime.Address.mailbox mailbox)
      | Error _ -> failwith (Fmt.strf "Invalid email address for 'to': %s" address))
  | Cc _ -> None
  | Bcc _ -> None

let cc_recipient_to_address : recipient -> Mrmime.Address.t option = fun recipient -> match recipient with
  | To _ -> None
  | Cc address -> (match Mrmime.Mailbox.of_string address with
      | Ok mailbox -> Some (Mrmime.Address.mailbox mailbox)
      | Error _ -> failwith (Fmt.strf "Invalid email address for 'to': %s" address))
  | Bcc _ -> None

let load_directory path =
  Lwt_unix.files_of_directory (Fpath.to_string path)
  |> Lwt_stream.map (Fpath.add_seg path)
  |> Lwt_stream.to_list

let load_file path =
  let open Lwt.Infix in
  Lwt_io.open_file ~mode:Lwt_io.Input (Fpath.to_string path) >>= fun ic ->
  Lwt_io.length ic >|= Int64.to_int >>= fun len ->
  let raw = Bytes.create len in
  Lwt_io.read_into_exactly ic raw 0 len >>= fun () ->
  Lwt.return (Bytes.unsafe_to_string raw)

let certs_of_pem path =
  let ( <.> ) f g = fun x -> f (g x) in
  let open Lwt.Infix in
  load_file path
  >|= (X509.Certificate.decode_pem <.> Cstruct.of_string)
  >|= Rresult.R.get_ok

let certs_of_pem_directory ?(ext= "crt") path =
  let ( <.> ) f g = fun x -> f (g x) in
  let open Lwt.Infix in
  load_directory path
  >>= Lwt_list.filter_p (Lwt.return <.> Fpath.has_ext ext)
  >>= Lwt_list.map_p certs_of_pem

let now () = Some (Ptime_clock.now ())

let build_email ~from ~recipients ~subject ~body =
  let open Mrmime in
  let subject = Unstructured.Craft.v subject in
  let date = Date.of_ptime ~zone:Date.Zone.GMT (Ptime_clock.now ()) in
  let from_addr = match Mailbox.of_string from with
    | Ok v -> v
    | Error _ -> failwith "Invalid email address for 'from'"
  in
  let to_addresses = List.filter_map to_recipient_to_address recipients in
  let cc_addresses = List.filter_map cc_recipient_to_address recipients in
  let headers =
    Field.(Field (Field_name.subject, Unstructured, subject))
    :: Field.(Field (Field_name.date, Date, date))
    :: Field.(Field (Field_name.from, Mailbox, from_addr))
    :: Field.(Field (Field_name.v "To", Addresses, to_addresses))
    :: Field.(Field (Field_name.cc, Addresses, cc_addresses))
    :: []
  in
  let plain_text_headers =
    let content1 =
      let open Content_type in
      make `Text (Subtype.v `Text "plain") Parameters.(of_list [ k "charset", v "utf-8" ])
    in
    Header.of_list Field.[
        Field (Field_name.content_type, Content, content1);
        Field (Field_name.content_encoding, Encoding, `Quoted_printable)
      ]
  in
  let html_headers =
    let content1 =
      let open Content_type in
      make `Text (Subtype.v `Text "html") Parameters.(of_list [ k "charset", v "utf-8" ])
    in
    Header.of_list Field.[
        Field (Field_name.content_type, Content, content1);
        Field (Field_name.content_encoding, Encoding, `Quoted_printable)
      ]
  in
  let body = match body with
    | Plain text -> Mt.part ~header:plain_text_headers (stream_of_string text)
    | Html text -> Mt.part ~header:html_headers (stream_of_string text)
  in
  Mt.make (Mrmime.Header.of_list headers) Mt.simple body

let send ~config:c ~recipients:r ~message:m =
  let (let*) = Lwt.bind in
  let authentication: Sendmail.authentication = {
    username = c.username;
    password = c.password;
    mechanism = Sendmail.PLAIN
  } in
  let port = match c.port, c.with_starttls with
    | None, true -> 587
    | None, false -> 465
    | Some v, _ -> v
  in
  let mail = Mrmime.Mt.to_stream m in
  let from_mailbox = match Emile.of_string c.sender with
    | Ok v -> v
    | Error `Invalid -> failwith "Invalid sender address"
  in
  let from_addr = match Colombe_emile.to_reverse_path from_mailbox with
    | Ok v -> v
    | Error `Msg msg -> failwith msg
  in
  let recipients = List.map (fun recipient -> (match recipient with
      | To a -> a
      | Cc a -> a
      | Bcc a -> a) |> str_to_colombe_address) r
  in
  let domain = match domain_of_reverse_path from_addr with
    | Ok v -> v
    | Error _ -> failwith "Failed to extract domain of sender address"
  in
  let hostname = match Domain_name.of_string c.hostname with
    | Error _ -> failwith "Config hostname is not valid hostname"
    | Ok hostname -> match Domain_name.host hostname with
      | Error _ -> failwith "Config hostname is not valid hostname"
      | Ok hostname -> hostname
  in
  let* certs = match Fpath.of_string c.ca_dir with
    | Ok path -> (certs_of_pem_directory ~ext:"pem" path)
    | Error _ -> failwith "Failed to open CA certificates directory"
  in
  let tls_authenticator = X509.Authenticator.chain_of_trust ~time:now certs in
  if c.with_starttls
  then
    let* res = Sendmail_handler.run_with_starttls ~hostname ~port ~domain ~authentication ~tls_authenticator ~from:from_addr ~recipients ~mail in
    match res with
    | Ok () -> Lwt.return (Ok ())
    | Error err -> Lwt.fail_with (Fmt.str "Sending email failed, %a" Sendmail_with_tls.pp_error err)
  else
    let* res = Sendmail_handler.run ~hostname ~port ~domain ~authentication ~tls_authenticator ~from:from_addr ~recipients ~mail in
    match res with
    | Ok () -> Lwt.return (Ok ())
    | Error err -> Lwt.fail_with (Fmt.str "Sending email failed, %a" Sendmail.pp_error err)
