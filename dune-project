(lang dune 2.3)
(name letters)
(version 0.2.0)

(generate_opam_files true)

(license MIT)
(authors "Miko Nieminen")
(maintainers "Miko Nieminen <miko.nieminen@iki.fi>")
(source (github oxidizing/letters))
(homepage "https://github.com/oxidizing/letters/")
(bug_reports "https://github.com/oxidizing/letters/issues")
(documentation "https://oxidizing.github.io/letters/")

(package
 (name letters)
 (synopsis "Client library for sending emails over SMTP")
 (description "Simple to use SMTP client implementation for OCaml")
 (depends
  (ocaml (>= 4.08.1))
  (dune (>= 2.3))
  (mrmime (>= 0.3.0))
  (colombe (>= 0.3.0))
  (sendmail-lwt (>= 0.3.0))
  (fmt (>= 0.8.8))
  (x509 (>= 0.9.0))
  (ptime (>= 0.8.5))
  (lwt (>= 5.2.0))
  (fpath (>= 0.7.0))

  ;; Test dependencies
  (alcotest (and (>= 1.1.0) :with-test))
  (alcotest-lwt (and (>= 1.1.0) :with-test))
  (yojson (and (>= 1.7.0) :with-test))

  ;; Dev dependencies
  (ocamlformat :dev)
 )
)
