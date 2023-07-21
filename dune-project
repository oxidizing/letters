(lang dune 2.7)

(name letters)

(version 0.3.3)

(generate_opam_files true)

(license MIT)

(authors "Miko Nieminen")

(maintainers "Miko Nieminen <miko.nieminen@iki.fi>")

(source
 (github oxidizing/letters))

(homepage "https://github.com/oxidizing/letters/")

(bug_reports "https://github.com/oxidizing/letters/issues")

(documentation "https://oxidizing.github.io/letters/")

(package
 (name letters)
 (synopsis "Client library for sending emails over SMTP")
 (description "Simple to use SMTP client implementation for OCaml")
 (depends
  (ca-certs
   (>= 0.2.1))
  (colombe
   (>= 0.7.0))
  (fmt
   (>= 0.8.8))
  (fpath
   (>= 0.7.0))
  (lwt
   (>= 5.2.0))
  (mrmime
   (>= 0.3.1))
  (ocaml
   (>= 4.08.1))
  (ptime
   (>= 0.8.5))
  (sendmail
   (>= 0.7.0))
  (tls-lwt
   (>= 0.16.0))
  (tls
   (>= 0.16.0))
  (x509
   (>= 0.9.0))
  ;; Test dependencies
  (alcotest
   (and
    (>= 1.1.0)
    :with-test))
  (alcotest-lwt
   (and
    (>= 1.1.0)
    :with-test))
  (yojson
   (and
    (>= 1.7.0)
    :with-test))
  ;; Documentation dependencies
  (odoc :with-doc)
  ;; Dev dependencies
  (ocamlformat :dev)))

(implicit_transitive_deps false)
