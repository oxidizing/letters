(lang dune 2.3)
(name letters)
(version dev)

(authors "Miko Nieminen <miko.nieminen@iki.fi>")
(maintainers "Miko Nieminen <miko.nieminen@iki.fi>")
(homepage "https://github.com/oxidizing/letters/")
(bug_reports "https://github.com/oxidizing/letters/issues")


(package
 (name letters)
 (synopsis "Client library for sending email over SMTP")
 (description "Simple to use SMTP client implementation for ocaml")
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
