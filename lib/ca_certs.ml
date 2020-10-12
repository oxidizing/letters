(* TODO delete this once https://github.com/mirage/ca-certs is on opam *)
let rec detect_list =
  let open Lwt in
  function
  | [] -> return_none
  | path :: paths ->
    Lwt_unix.file_exists path
    >>= fun exists -> if exists then return_some (`Ca_file path) else detect_list paths
;;

let locations =
  [ "/etc/ssl/certs/ca-certificates.crt"
  ; "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem"
  ]
;;

let detect () = detect_list locations
