(** Configuration providing needed information to connect to the SMTP server. *)
module Config : sig
  type t

  val make :
    username:string ->
    password:string ->
    hostname:string ->
    with_starttls:bool ->
    t
  (** Build a configuration record for the SMTP server
   ** This is a helper to build a configuration.
   **
   ** [sender] email address of the user
   ** [username] username needed for the login
   ** [password] user's password for the login
   ** [hostname] hostname of the SMTP server
   ** *)

  val set_port : int option -> t -> t
  (** Add a port to configuration record
   ** This is a helper function to allow builder pattern.
   ** Creates a new config with the provided optional port and old config.
   ** The port is used to connect the SMTP server or None for using default port
   ** *)

  val set_ca_dir : Lwt_io.file_name option -> t -> t
  (** Add a ca cert dir to configuration record
   ** This is a helper function to allow builder pattern.
   ** Creates a new config with the provided optional ca cert dir and old config.
   ** This library does not allow unencrypted SMTP connections.
   ** The ca cert dir is the system location where all CA certificates (in PEM
   ** format) are expected to be found when verifying server certificate.
   ** *)
end

type body =
  | Plain of string
  | Html of string
  | Mixed of string * string * string option

type recipient = To of string | Cc of string | Bcc of string

val build_email :
  from:string ->
  recipients:recipient list ->
  subject:string ->
  body:body ->
  (Mrmime.Mt.t, string) result
(** Build an email using mrmime
 ** This function is a helper function to simplify process of building an email
 ** with `mrmime`. It will return result type and wraps all exceptions into Error
 ** [from] string representation of the email proved as a `from` field, this can
 ** be a different email address than the [config.sender].
 ** [recipients] list of email recipients
 ** [subject] the single line string used as the email `subject` field
 ** [body] string representation of the actual email message that can be either
 ** plain text or HTML message
 ** Returns [result] indicating if built email is valid or Error if anything
 ** failed
 ** *)

val send :
  config:Config.t ->
  sender:string ->
  recipients:recipient list ->
  message:Mrmime.Mt.t ->
  unit Lwt.t
(** Send the previously generated email
 ** This function expects valid configuration, list of recipients and finally a
 ** valid `mrmime` representation of the email message.
 ** [config] valid configuration to connect the SMTP server.
 ** [recipients] list of valid email addresses.
 ** [message] valid `mrmime` representation of the email message.
 ** Runs asynchronously using Lwt and retuns unit when the message is sent
 ** successfully. If anything fails during the process, throws an exception.
 ** *)
