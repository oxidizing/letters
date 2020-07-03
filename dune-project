(lang dune 2.3)
(name letters)
(version 0.1.0)

(generate_opam_files true)

(authors "Miko Nieminen")

(package
 (name letters)
 (synopsis "Client library for sending email using SMTP")
 (description "Simplified SMTP client implementation")
 (depends
  (ocaml (>= 4.03.0))
  (dune (>= 2.0))
  (mrmime (= 0.3.0))
  (colombe (= 0.3.0))
  (sendmail-lwt (= 0.3.0))
  (fmt (= 0.8.8))
  (x509 (>= 0.9.0))
  (ptime (>= 0.8.5))
  (lwt (and (>= 5.2.0) (< 6.0.0)))
  fpath

  ;; Test dependencies
  (alcotest (and (>= 1.1.0) :with-test))
  (alcotest-lwt (and (>= 1.1.0) :with-test))
  (yojson (and (>= 1.7.0) (< 2.0.0) :with-test))
 )
)
