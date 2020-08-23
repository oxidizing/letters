open Letters

let ( let* ) = Lwt.bind

let get_ethereal_account_details () =
  let open Yojson.Basic.Util in
  (* see the README.md how to generate the account file and the path
   * below is relative to the location of the executable under _build
   *)
  let json = Yojson.Basic.from_file "../../../ethereal_account.json" in
  let username = json |> member "user" |> to_string in
  let password = json |> member "pass" |> to_string in
  let smtp_node = json |> member "smtp" in
  let hostname = smtp_node |> member "host" |> to_string in
  let port = smtp_node |> member "port" |> to_int in
  let with_starttls = smtp_node |> member "secure" |> to_bool |> not in
  Config.make ~username ~password ~hostname ~with_starttls
  |> Config.set_port (Some port)
  |> Lwt.return

let test_send_plain_text_email config _ () =
  let sender =
    Yojson.Basic.from_file "../../../ethereal_account.json"
    |> Yojson.Basic.Util.member "user"
    |> Yojson.Basic.Util.to_string
  in
  let recipients =
    [
      To "harry@example.com";
      To "larry@example.com";
      Cc "bill@example.com";
      Bcc "dave@example.com";
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

let test_send_html_email config _ () =
  let sender =
    Yojson.Basic.from_file "../../../ethereal_account.json"
    |> Yojson.Basic.Util.member "user"
    |> Yojson.Basic.Util.to_string
  in
  let recipients =
    [
      To "harry@example.com";
      To "larry@example.com";
      Cc "bill@example.com";
      Bcc "dave@example.com";
    ]
  in
  let subject = "HTML only test email" in
  let body =
    Html
      {|
<p>Hi there,</p>
<p>
  have you already seen the very cool new web framework written in ocaml:
  <a href="https://github.com/oxidizing/sihl">Sihl</a>
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

let test_send_mixed_body_email config _ () =
  let sender =
    Yojson.Basic.from_file "../../../ethereal_account.json"
    |> Yojson.Basic.Util.member "user"
    |> Yojson.Basic.Util.to_string
  in
  let recipients =
    [
      To "harry@example.com";
      To "larry@example.com";
      Cc "bill@example.com";
      Bcc "dave@example.com";
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
<p>Hi there,</p>
<p>
  have you already seen the very cool new web framework written in ocaml:
  <a href="https://github.com/oxidizing/sihl">Sihl</a>
<p>
Regards,<br>
The team
</p>
|}
  in
  let mail =
    build_email ~from:sender ~recipients ~subject
      ~body:(Mixed (text, html, None))
  in
  match mail with
  | Ok message -> send ~config ~sender ~recipients ~message
  | Error reason -> Lwt.fail_with reason

(* Run it *)
let () =
  Lwt_main.run
    (let* conf_with_ca_detect = get_ethereal_account_details () in
     let conf_with_ca_cert_bundle =
       Config.set_ca_cert "/etc/ssl/certs/ca-certificates.crt"
         conf_with_ca_detect
     in
     let conf_with_single_ca_cert =
       (* ethereal.mail's certificate is signed with Let's Encrypt Authority X3
        *  that signed by DST Root CA X3 *)
       Config.set_ca_cert "/etc/ssl/certs/DST_Root_CA_X3.pem"
         conf_with_ca_detect
     in
     let conf_with_ca_path =
       Config.set_ca_path "/etc/ssl/certs/" conf_with_ca_detect
     in
     Alcotest_lwt.run "STMP client"
       [
         ( "use ethereal.email, auto-detect CA certs",
           [
             Alcotest_lwt.test_case "Send plain text email" `Slow
               (test_send_plain_text_email conf_with_ca_detect);
             Alcotest_lwt.test_case "Send html email" `Slow
               (test_send_html_email conf_with_ca_detect);
             Alcotest_lwt.test_case "Send send mixed body email" `Slow
               (test_send_mixed_body_email conf_with_ca_detect);
           ] );
         ( "use ethereal.email, define certificate bundle location",
           [
             Alcotest_lwt.test_case "Send plain text email" `Slow
               (test_send_plain_text_email conf_with_ca_cert_bundle);
             Alcotest_lwt.test_case "Send html email" `Slow
               (test_send_html_email conf_with_ca_cert_bundle);
             Alcotest_lwt.test_case "Send send mixed body email" `Slow
               (test_send_mixed_body_email conf_with_ca_cert_bundle);
           ] );
         ( "use ethereal.email, define location single CA cert",
           [
             Alcotest_lwt.test_case "Send plain text email" `Slow
               (test_send_plain_text_email conf_with_single_ca_cert);
             Alcotest_lwt.test_case "Send html email" `Slow
               (test_send_html_email conf_with_single_ca_cert);
             Alcotest_lwt.test_case "Send send mixed body email" `Slow
               (test_send_mixed_body_email conf_with_single_ca_cert);
           ] );
         ( "use ethereal.email, define PEM folder path",
           [
             Alcotest_lwt.test_case "Send plain text email" `Slow
               (test_send_plain_text_email conf_with_ca_path);
             Alcotest_lwt.test_case "Send html email" `Slow
               (test_send_html_email conf_with_ca_path);
             Alcotest_lwt.test_case "Send send mixed body email" `Slow
               (test_send_mixed_body_email conf_with_ca_path);
           ] );
       ])
