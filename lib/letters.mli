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

      This is a helper to build a configuration.

      [username] username needed for the login

      [password] user's password for the login

      [hostname] hostname of the SMTP server

      [with_starttls] True if start unencrypted connection and then "promote"
      *)

  val set_port : int option -> t -> t
  (** Add a port to configuration record

      This is a helper function to allow builder pattern.

      Creates a new config with the provided optional port and old config.
      The port is used to connect the SMTP server or None for using default port
      *)

  val set_ca_cert : Lwt_io.file_name -> t -> t
  (** Tells letters to use the specified certificate to verify the peer.

      The file may contain multiple CA certificates. The certificate(s) must be in
      PEM format.

      Creates a new config with the provided CA cert and old config.
      *)

  val set_ca_path : Lwt_io.file_name -> t -> t
  (** Tells letters to use the specified certificate director to verify the peer.

      Each certificate in the folder must be in PEM format.

      Creates a new config with the provided CA cert dir and old config.
      *)
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

    This function is a helper function to simplify process of building an email
    with `mrmime`. It will return result type and wraps all exceptions into Error

    [from] string representation of the email proved as a `from` field, this can
    be a different email address than the [config.sender].

    [recipients] list of email recipients

    [subject] the single line string used as the email `subject` field

    [body] string representation of the actual email message that can be either
    plain text or HTML message

    Returns [result] indicating if built email is valid or Error if anything
    failed
    *)

val send :
  config:Config.t ->
  sender:string ->
  recipients:recipient list ->
  message:Mrmime.Mt.t ->
  unit Lwt.t
(** Send the previously generated email

    This function expects valid configuration, list of recipients and finally a
    valid `mrmime` representation of the email message.

    [config] valid configuration to connect the SMTP server.

    [recipients] list of valid email addresses.

    [message] valid `mrmime` representation of the email message.

    Runs asynchronously using Lwt and retuns unit when the message is sent
    successfully. If anything fails during the process, throws an exception.
    *)
