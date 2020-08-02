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
  |> Config.set_ca_dir (Some "/etc/ssl/certs")
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
    Plain {|
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
    Html {|
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
  let text = {|
Hi there,

have you already seen the very cool new web framework written in ocaml:
https://github.com/oxidizing/sihl

Regards,
The team
|}
  in
  let html = {|
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
  let mail = build_email ~from:sender ~recipients ~subject ~body:(Mixed (text, html, None)) in
  match mail with
  | Ok message -> send ~config ~sender ~recipients ~message
  | Error reason -> Lwt.fail_with reason

(* Run it *)
let () =
  Lwt_main.run
     (let* conf = get_ethereal_account_details () in
     Alcotest_lwt.run "STMP client"
       [
         ( "use ethereal.email service",
           [
             Alcotest_lwt.test_case "Send plain text email" `Quick
               (test_send_plain_text_email conf);
             Alcotest_lwt.test_case "Send html email" `Quick
               (test_send_html_email conf);
             Alcotest_lwt.test_case "Send send mixed body email" `Quick
               (test_send_mixed_body_email conf);
           ] );
       ])
