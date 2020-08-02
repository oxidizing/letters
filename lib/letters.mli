module Config : sig
  type t

  val make :
    username:string ->
    password:string ->
    hostname:string ->
    with_starttls:bool ->
    t

  val set_port : int option -> t -> t

  val set_ca_dir : Lwt_io.file_name option -> t -> t
end

type body = Plain of string | Html of string

type recipient = To of string | Cc of string | Bcc of string

val build_email :
  from:string ->
  recipients:recipient list ->
  subject:string ->
  body:body ->
  Mrmime.Mt.t

val send :
  config:Config.t ->
  recipients:recipient list ->
  message:Mrmime.Mt.t ->
  (unit, string) Lwt_result.t
