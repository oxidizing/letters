(* TODO delete this once https://github.com/mirage/ca-certs is on opam *)

(** Detect root CAs in the operating system's trust store. Returns [None] if detection did
    not succeed. The variants correspond to the ones used in [X509_lwt] in [ocaml-tls]. *)
val detect : unit -> [> `Ca_file of Lwt_io.file_name ] option Lwt.t
