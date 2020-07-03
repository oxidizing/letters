module Lwt_scheduler = Colombe.Sigs.Make(Lwt)

let ( <.> ) f g = fun x -> f (g x)

let lwt_bind x f =
  let open Lwt.Infix in
  let open Lwt_scheduler in
  inj (prj x >>= (prj <.> f))

let lwt =
  { Colombe.Sigs.bind= lwt_bind
  ; return= (fun x -> Lwt_scheduler.inj (Lwt.return x)) }

type flow =
  { ic : Lwt_io.input_channel
  ; oc : Lwt_io.output_channel }

let rdwr =
  { Colombe.Sigs.rd= (fun { ic; _ } bytes off len ->
        let res = Lwt_io.read_into ic bytes off len in
        Lwt_scheduler.inj res)
  ; wr= (fun { oc; _ } bytes off len ->
        let res = Lwt_io.write_from_exactly oc (Bytes.unsafe_of_string bytes) off len in
        Lwt_scheduler.inj res) }

let run_with_starttls ~hostname ?port ~domain ~authentication ~tls_authenticator ~from ~recipients ~mail =
  let port = match port with Some port -> port | None -> 465 in
  let tls = Tls.Config.client ~authenticator:tls_authenticator () in
  let ctx = Sendmail_with_tls.Context_with_tls.make () in
  let open Lwt.Infix in

  Lwt_unix.gethostbyname (Domain_name.to_string hostname) >>= fun res ->
  if Array.length res.Lwt_unix.h_addr_list = 0
  then Lwt.fail_with (Fmt.strf "%a can not be resolved" Domain_name.pp hostname)
  else
    let socket = Lwt_unix.socket Lwt_unix.PF_INET Unix.SOCK_STREAM 0 in
    Lwt_unix.connect socket (Lwt_unix.ADDR_INET (res.Lwt_unix.h_addr_list.(0), port)) >>= fun () ->

    let closed = ref false in
    let close () = if !closed then Lwt.return () else ( closed := true ; Lwt_unix.close socket ) in
    let ic = Lwt_io.of_fd ~close ~mode:Lwt_io.Input socket in
    let oc = Lwt_io.of_fd ~close ~mode:Lwt_io.Output socket in

    let mail_stream = fun () -> match mail () with
      | Some v -> Lwt_scheduler.inj (Lwt.return (Some v))
      | None -> Lwt_scheduler.inj (Lwt.return None)
    in

    let fiber = Sendmail_with_tls.sendmail lwt rdwr { ic; oc; } ctx tls ~authentication ~domain from recipients mail_stream in
    Lwt_scheduler.prj fiber

let run ~hostname ?port ~domain ~authentication ~tls_authenticator ~from ~recipients ~mail =
  let ( let* ) = Lwt.bind in
  let port = match port with Some port -> port | None -> 465 in
  let ctx = Colombe.State.Context.make () in
  let* (ic, oc) = Tls_lwt.connect tls_authenticator ((Domain_name.to_string hostname), port) in
  let mail_stream = fun () -> match mail () with
    | Some v -> Lwt_scheduler.inj (Lwt.return (Some v))
    | None -> Lwt_scheduler.inj (Lwt.return None)
  in
  let fiber = Sendmail.sendmail lwt rdwr { ic; oc; } ctx ~authentication ~domain from recipients mail_stream in
  Lwt_scheduler.prj fiber
