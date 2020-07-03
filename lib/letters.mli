
type config = {
    sender: string;
    username: string;
    password: string;
    hostname: string;
    port: int option;
    with_starttls: bool;
    ca_dir: string;
}

type body = Plain of string | Html of string

type recipient = To of string | Cc of string | Bcc of string

val build_email :
  from: string ->
  recipients: recipient list ->
  subject: string ->
  body: body ->
  Mrmime.Mt.t

val send :
  config: config ->
  recipients: recipient list ->
  message: Mrmime.Mt.t ->
  (unit, string) Lwt_result.t
