val run_with_starttls
  :  hostname:'a Domain_name.t
  -> ?port:int
  -> domain:Colombe.Domain.t
  -> authentication:Sendmail.authentication
  -> tls_authenticator:X509.Authenticator.t
  -> from:Colombe.Reverse_path.t
  -> recipients:Colombe.Forward_path.t list
  -> mail:Mrmime.Mt.buffer Mrmime.Mt.stream
  -> (unit, Sendmail_with_starttls.error) Lwt_result.t

val run
  :  hostname:'a Domain_name.t
  -> ?port:int
  -> domain:Colombe.Domain.t
  -> authentication:Sendmail.authentication
  -> tls_authenticator:X509.Authenticator.t
  -> from:Colombe.Reverse_path.t
  -> recipients:Colombe.Forward_path.t list
  -> mail:Mrmime.Mt.buffer Mrmime.Mt.stream
  -> (unit, Sendmail.error) Lwt_result.t
