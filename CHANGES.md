# Changelog

## [0.2.1] - 2020-12-07
### Fixed
- Upgrade to `colombe` version `0.4.0`, this fixes vanishing full stop issue,
  when encoded mail body contains line that stars with full stop. See
  [SMTP Transparency](https://tools.ietf.org/html/rfc821#section-4.5.2) for more
  information.
### Changed
- Improve service tests
- Improve documentation for running service tests
### Added
- Use also *mailtrap.io* in service tests

## [0.2.0] - 2020-08-25
### Added
- Support for multipart/alternative emails supporting HTML and plain text bodies
  as alternative representation for the content
- Add documentation for basic use
- Add support for detecting CA certificates automatically for peer verification
- Add support defining bundle or single CA certificate for peer verification
- Add support for selecting mechanism for CA certificates used for peer
  verification
### Changed
- Refactor configurations into separate module
- Refactor structure of tests

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
