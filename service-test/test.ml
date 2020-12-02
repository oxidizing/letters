open Letters

let ( let* ) = Lwt.bind

let get_ethereal_account_details () =
  let open Yojson.Basic.Util in
  (* see the README.md how to generate the account file and the path
   * below is relative to the location of the executable under _build
   *)
  let json = Yojson.Basic.from_file "../../../ethereal_account.json" in
  let username = json |> member "username" |> to_string in
  let password = json |> member "password" |> to_string in
  let hostname = json |> member "hostname" |> to_string in
  let port = json |> member "port" |> to_int in
  let with_starttls = json |> member "secure" |> to_bool |> not in
  Config.make ~username ~password ~hostname ~with_starttls
  |> Config.set_port (Some port)
  |> Lwt.return
;;

let get_mailtrap_account_details () =
  let open Yojson.Basic.Util in
  (* see the README.md how to generate the account file and the path
   * below is relative to the location of the executable under _build
   *)
  let json = Yojson.Basic.from_file "../../../mailtrap_account.json" in
  let username = json |> member "username" |> to_string in
  let password = json |> member "password" |> to_string in
  let hostname = json |> member "hostname" |> to_string in
  let port = json |> member "port" |> to_int in
  let with_starttls = json |> member "secure" |> to_bool |> not in
  Config.make ~username ~password ~hostname ~with_starttls
  |> Config.set_port (Some port)
  |> Lwt.return
;;

let test_send_plain_text_email config _ () =
  let sender = "john@example.com" in
  let recipients =
    [ To "harry@example.com"
    ; To "larry@example.com"
    ; Cc "bill@example.com"
    ; Bcc "dave@example.com"
    ]
  in
  let subject = "Plain text test email" in
  let body =
    Plain
      {|
Hi there,

have you already seen the very cool new web framework written in ocaml:
https://github.com/oxidizing/sihl

Regards,
The team
|}
  in
  let mail = build_email ~from:sender ~recipients ~subject ~body in
  match mail with
  | Ok message -> send ~config ~sender ~recipients ~message
  | Error reason -> Lwt.fail_with reason
;;

let test_send_html_email config _ () =
  let sender = "john@example.com" in
  let recipients =
    [ To "harry@example.com"
    ; To "larry@example.com"
    ; Cc "bill@example.com"
    ; Bcc "dave@example.com"
    ]
  in
  let subject = "HTML only test email" in
  let body =
    Html
      {|
<h>Hi there,</h>
<p>
  have you already seen the very cool new web framework written in ocaml:
  <a href="https://github.com/oxidizing/sihl">Sihl</a>
</p>
<p>
  Regards,<br>
  The team
</p>
|}
  in
  let mail = build_email ~from:sender ~recipients ~subject ~body in
  match mail with
  | Ok message -> send ~config ~sender ~recipients ~message
  | Error reason -> Lwt.fail_with reason
;;

let test_send_mixed_body_email config _ () =
  let sender = "john@example.com" in
  let recipients =
    [ To "harry@example.com"
    ; To "larry@example.com"
    ; Cc "bill@example.com"
    ; Bcc "dave@example.com"
    ]
  in
  let subject = "Mixed body email with plain text and HTML" in
  let text =
    {|
Hi there,

have you already seen the very cool new web framework written in ocaml:
https://github.com/oxidizing/sihl

Regards,
The team
|}
  in
  let html =
    {|
<h>Hi there,</h>
<p>
  have you already seen the very cool new web framework written in ocaml:
  <a href="https://github.com/oxidizing/sihl">Sihl</a>
</p>
<p>
  Regards,<br>
  The team
</p>
|}
  in
  let mail =
    build_email ~from:sender ~recipients ~subject ~body:(Mixed (text, html, None))
  in
  match mail with
  | Ok message -> send ~config ~sender ~recipients ~message
  | Error reason -> Lwt.fail_with reason
;;

let test_send_mixed_body_email_with_dot_starting_a_line config _ () =
  let sender = "john@example.com" in
  let recipients =
    [ To "harry@example.com"
    ; To "larry@example.com"
    ; Cc "bill@example.com"
    ; Bcc "dave@example.com"
    ]
  in
  let subject = "Mixed body email with dot starting a line in raw source" in
  let text =
    {|
This email is carefully crafted so that the dot in the URL is expected to hit
the beginning of a new line in the encoded body, this tests that the case is
correctly handled and the dot does not vanish:: https://github.com/oxidizing/sihl
|}
  in
  let html =
    {|
<div>
This email is carefully crafted so that the dot in the URL is expected to hit
the beginning of a new line in the encoded body, this tests that the case is
correctly handled and the dot does not vanish that would render this URL
broken:::  <a href="https://github.com/oxidizing/sihl">Sihl</a>
</div>
|}
  in
  let mail =
    build_email ~from:sender ~recipients ~subject ~body:(Mixed (text, html, None))
  in
  match mail with
  | Ok message -> send ~config ~sender ~recipients ~message
  | Error reason -> Lwt.fail_with reason
;;

(* Run it *)
let () =
  Lwt_main.run
    (let* ethereal_conf_with_ca_detect = get_ethereal_account_details () in
     let* mailtrap_conf_with_ca_detect = get_mailtrap_account_details () in
     let ethereal_conf_with_ca_cert_bundle =
       Config.set_ca_cert
         "/etc/ssl/certs/ca-certificates.crt"
         ethereal_conf_with_ca_detect
     in
     let ethereal_conf_with_single_ca_cert =
       (* ethereal.mail's certificate is signed with Let's Encrypt Authority X3
        *  that signed by DST Root CA X3 *)
       Config.set_ca_cert "/etc/ssl/certs/DST_Root_CA_X3.pem" ethereal_conf_with_ca_detect
     in
     let ethereal_conf_with_ca_path =
       Config.set_ca_path "/etc/ssl/certs/" ethereal_conf_with_ca_detect
     in
     Alcotest_lwt.run
       "STMP client"
       [ ( "use ethereal.email, auto-detect CA certs"
         , [ Alcotest_lwt.test_case
               "Send plain text email, auto-detect CA certs"
               `Slow
               (test_send_plain_text_email ethereal_conf_with_ca_detect)
           ; Alcotest_lwt.test_case
               "Send plain text email, use CA cert bundle"
               `Slow
               (test_send_plain_text_email ethereal_conf_with_ca_cert_bundle)
           ; Alcotest_lwt.test_case
               "Send plain text email, use specific CA cert file"
               `Slow
               (test_send_plain_text_email ethereal_conf_with_single_ca_cert)
           ; Alcotest_lwt.test_case
               "Send plain text email, load CA certificates from a folder"
               `Slow
               (test_send_plain_text_email ethereal_conf_with_ca_path)
           ] )
       ; ( "use ethereal.email, test different email message types"
         , [ Alcotest_lwt.test_case
               "Send plain text email"
               `Slow
               (test_send_plain_text_email ethereal_conf_with_ca_detect)
           ; Alcotest_lwt.test_case
               "Send HTML only email"
               `Slow
               (test_send_html_email ethereal_conf_with_ca_detect)
           ; Alcotest_lwt.test_case
               "Send mixed content email with plain text and HTML"
               `Slow
               (test_send_mixed_body_email ethereal_conf_with_ca_detect)
           ; Alcotest_lwt.test_case
               "Send email with content including line starting with dot (SMTP \
                Transparency)"
               `Slow
               (test_send_mixed_body_email_with_dot_starting_a_line
                  ethereal_conf_with_ca_detect)
           ] )
       ; ( "use mailtrap, test different email message types"
         , [ Alcotest_lwt.test_case
               "Send plain text email"
               `Slow
               (test_send_plain_text_email mailtrap_conf_with_ca_detect)
           ; Alcotest_lwt.test_case
               "Send HTML only email"
               `Slow
               (test_send_html_email mailtrap_conf_with_ca_detect)
           ; Alcotest_lwt.test_case
               "Send mixed content email with plain text and HTML"
               `Slow
               (test_send_mixed_body_email mailtrap_conf_with_ca_detect)
           ; Alcotest_lwt.test_case
               "Send email with content including line starting with dot (SMTP \
                Transparency)"
               `Slow
               (test_send_mixed_body_email_with_dot_starting_a_line
                  mailtrap_conf_with_ca_detect)
           ] )
       ])
;;
