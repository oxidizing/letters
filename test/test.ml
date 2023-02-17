open Letters

let stream_to_string s =
  let b = Buffer.create 4096 in
  let rec go () =
    match s () with
    | Some (buf, off, len) ->
      Buffer.add_substring b buf off len;
      go ()
    | None -> Buffer.contents b
  in
  go ()
;;

let test_create_plain_text_email _ () =
  let recipients = [ To "dave@example.com" ] in
  let subject = "Hello" in
  let body = Plain "Hello Dave" in
  let mail = create_email ~from:"harry@example.com" ~recipients ~subject ~body () in
  let stream =
    match mail with
    | Ok mail -> Mrmime.Mt.to_stream mail
    | Error reason -> failwith reason
  in
  let message = stream_to_string stream in
  Lwt.return (print_string message)
;;

let test_create_html_email _ () =
  let recipients = [ To "dave@example.com" ] in
  let subject = "Hello" in
  let body = Html "<i>Hello Dave</i>" in
  let mail = create_email ~from:"harry@example.com" ~recipients ~subject ~body () in
  let stream =
    match mail with
    | Ok mail -> Mrmime.Mt.to_stream mail
    | Error reason -> failwith reason
  in
  let message = stream_to_string stream in
  Lwt.return (print_string message)
;;

let test_create_mixed_body_email _ () =
  let recipients = [ To "dave@example.com" ] in
  let subject = "Hello" in
  let body = Mixed ("Hello Dave", "<i>Hello Dave</i>", Some "blaablaa") in
  let mail = create_email ~from:"harry@example.com" ~recipients ~subject ~body () in
  let stream =
    match mail with
    | Ok mail -> Mrmime.Mt.to_stream mail
    | Error reason -> failwith reason
  in
  let message = stream_to_string stream in
  Lwt.return (print_string message)
;;

let test_create_config () =
  (* check for config compatibility *)
  let username, password, hostname, with_starttls =
    "SomeUser", "password", "localhost", true
  in
  let[@warning "-3"] (_ : Config.t) =
    Config.make ~username ~password ~hostname ~with_starttls
  in
  let (_ : Config.t) = Config.create ~username ~password ~hostname ~with_starttls () in
  let (_ : Config.t) =
    Config.create
      ~mechanism:Sendmail.LOGIN
      ~username
      ~password
      ~hostname
      ~with_starttls
      ()
  in
  ()
;;

let () =
  let () =
    Alcotest.(
      run "model" [ "config", [ test_case "create config" `Quick test_create_config ] ])
  in
  Lwt_main.run
    (Alcotest_lwt.run
       "Email creation"
       [ ( "Generating body"
         , [ Alcotest_lwt.test_case
               "email with plain text body"
               `Quick
               test_create_plain_text_email
           ; Alcotest_lwt.test_case
               "email with HTML text body"
               `Quick
               test_create_html_email
           ; Alcotest_lwt.test_case
               "email with mixed plain text and HTML body"
               `Quick
               test_create_mixed_body_email
           ] )
       ])
;;
