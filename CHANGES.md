# Changelog

## [0.1.1] - 2020-07-10
### Fixed
- Add missing `public_name` stanza in library's dune file to make it properly
available
- Fix minimum required OCaml version to 4.08.1
- Relax `mrmime` and `colombe` dependency constraints

## [0.1.0] - 2020-07-07
### Added
- Support sending email over TLS protected SMTP connection
- Support sending email over SMTP with STARTTLS
- Support sending HTML or plain text body
