# &#9993; Letters &middot; [![CircleCI](https://circleci.com/gh/oxidizing/letters.svg?style=shield)](https://circleci.com/gh/oxidizing/letters) ![GitHub](https://img.shields.io/github/license/oxidizing/letters)

Letters is a library for creating and sending emails over SMTP using [Lwt](https://github.com/ocsigen/lwt).

## Table of Contents
* [Use](#use)
  * [Configuration](#configuration)
  * [Building emails](#building-emails)
  * [Sending emails](#building-emails)
  * [Examples](#examples)
* [Development](#development)
  * [Setup](#setup)
  * [Build](#build)
  * [Tests](#tests)
    * [Unit tests](#unit-tests)
    * [Service tests](#service-tests)
* [Credits](#credits)
* [License](#license)

## Use

Purpose of the library is to make it easier to send emails when building systems using OCaml. Currently the API consists of three parts:
1. configuration
2. building email messages
3. sending email messages

Whole API is in `lib/letters.mli` that contains also some additional documentation.

Keep in mind that this library is in its early days and the API is changing with every release. Also this is tested only on Linux based systems and testing is pretty weak and manual. Though the library has been used successfully.

### Configuration

Most simple use case would look something like:

``` ocaml
let conf = Config.make ~username:"myuser" ~password:"mypasswd" ~hostname:"smtp.ethereal.email" ~with_starttls:true
```
This will use port `587`, uses STARTTLS for encryption and tries automatically find CA certificates for verifying server connection.

Port `587` is default when using STARTTLS. If you set `~with_starttls:false`, then the default port will be `465`.

This library does **not** support SMTP connections without TLS encryption or authentication. For TLS encryption, this library uses [ocaml-tls](https://opam.ocaml.org/packages/tls/).

If you want to change the server port you can do it with `Config.set_port` (passing `None` causes default port to be used):

``` ocaml
let conf = Config.make ~username:"myuser" ~password:"mypasswd" ~hostname:"smtp.ethereal.email" ~with_starttls:true
|> Config.set_port (Some 2525)
```

If the CA certificate auto-detection does not work for you (it's very na&iuml;ve implementation), you can define path to a certificate bundle or to a single PEM encoded certificate, or you can define path to a folder containing multiple PEM encoded certificate files.

To use a CA certificate bundle (each included certificate needs to be PEM encoded):

``` ocaml
let conf = Config.make ~username:"myuser" ~password:"mypasswd" ~hostname:"smtp.ethereal.email" ~with_starttls:true
|> Config.set_ca_cert "/etc/ssl/certs/ca-certificates.crt"
```

To use a single PEM encoded CA certificate:

``` ocaml
let conf = Config.make ~username:"myuser" ~password:"mypasswd" ~hostname:"smtp.ethereal.email" ~with_starttls:true
|> Config.set_ca_cert "/etc/ssl/certs/DST_Root_CA_X3.pem"
```

To use all PEM encoded certificate files from a folder:

``` ocaml
let conf = Config.make ~username:"myuser" ~password:"mypasswd" ~hostname:"smtp.ethereal.email" ~with_starttls:true
|> Config.set_ca_path "/etc/ssl/certs/"
```

### Building emails

Building an email is separated into its own step so that you can use [mrmime](https://opam.ocaml.org/packages/mrmime/) to generate more complex emails when this simplified API does not work for you.

To use our provided API, you can build three kinds of emails:
1. `Plain`, plain text
2. `Html`, HTML only
3. `Mixed`, multipart/alternative containing both: plain text and HTMl segments

If you're not sure, either use `Plain` or `Mixed`.

Example of building a plain text email:

``` ocaml
let sender = "harry@example.com" in
let recipients =
  [
    To "larry@example.com";
    Cc "bill@example.com";
    Bcc "dave@example.com";
  ]
in
let subject = "HTML only test email" in
let body =
  Plain
    {|
Hi there,

This is a test email from https://github.com/oxidizing/letters

Regards,
The Letters team
|}
  in
  let mail = build_email ~from:sender ~recipients ~subject ~body in
```

Example of building an HTML only email:

``` ocaml
let sender = "harry@example.com" in
let recipients =
  [
    To "larry@example.com";
    Cc "bill@example.com";
    Bcc "dave@example.com";
  ]
in
let subject = "HTML only test email" in
let body =
  Html
    {|
<p>Hi there,</p>
<p>
    This is a test email from
    <a href="https://github.com/oxidizing/letters">letters</a>
<p>
Regards,<br>
The Letters team
</p>
|}
in
let mail = build_email ~from:sender ~recipients ~subject ~body in
```

Example of building an email with plain text and HTMl segments:

``` ocaml
let sender = "harry@example.com" in
let recipients =
  [
    To "larry@example.com";
    Cc "bill@example.com";
    Bcc "dave@example.com";
  ]
in
let subject = "HTML only test email" in
let text =
  {|
Hi there,

This is a test email from https://github.com/oxidizing/letters

Regards,
The Letters team
|}
in
let html =
  {|
<p>Hi there,</p>
<p>
    This is a test email from
    <a href="https://github.com/oxidizing/letters">letters</a>
<p>
Regards,<br>
The Letters team
|}
in
let mail = build_email ~from:sender ~recipients ~subject ~body:(Mixed (text, html, None)) in
```

`Letters.build_email` returns `result` so you need to map it accordingly:

``` ocaml
let mail = build_email ~from:sender ~recipients ~subject ~body:(Mixed (text, html, None)) in
match mail with
| Ok message -> do_something message
| Error reason -> handle_error reason
```

### Sending emails

Sending is single API call `Letters.send` that looks like following (when using `config`, `sender`, `recipients` and `message` from previous examples):

``` ocaml
send ~config ~sender ~recipients ~message
```

Return type is `Lwt.t` so you need to run it with appropriate `Lwt` routines.

### Examples

See `service-test/test.ml` for complete examples that are using *ethereal.email* service to test sending emails.

## Development

### Setup

``` shell
opam switch create . ocaml-base-compiler.4.08.1
eval $(opam env)
opam install --deps-only -y . --with-test
```

### Build

``` shell
dune build
```

### Tests

#### Unit tests

Run with default `test` target of `dune`:

``` shell
dune build @runtest
```

These tests are still somewhat far from good and you need to validate all results manually by checking the test output logs.

#### Service tests

These tests are somewhat slow and fragile and because of that these are expected to be run manually.

First create *ethereal.email* account and store account details

``` shell
curl -d '{ "requestor": "letters", "version": "dev" }' "https://api.nodemailer.com/user" -X POST -H "Content-Type: application/json" > ethereal_account.json
```

Currently using `ethereal.email` service requires non-released version of `colombe` and
you need to check out the project, commit `edf757c58fce58c170c63e8a92d3bc81fe4d32ff` contains the needed fix. Then the version with the fix needs to be pinned in the build env:

``` shell
# Move to folder where colombe is checked out
pushd /path/to/colombe
# Switch to correct git commit in colombe repo
git switch --detach edf757c58fce58c170c63e8a92d3bc81fe4d32ff
# Switch to use same opam env that is used by letters
eval "$(opam env --switch $(dirs | cut -d ' ' -f 2) --set-switch)"
# Pin this specific version of colombe (and all related packages)
opam pin .
# Finally, return back to letters project
popd
```

Then execute these tests (actually this runs all tests):

``` shell
dune build @runtest-all
```

And finally review that the email is correctly generated in the service:
- login to https://ethereal.email/login using credentials from the `ethereal_account.json`
- check the content of messages: https://ethereal.email/messages

## Credits

This project is build on [colombe](https://github.com/mirage/colombe "colombe project") and [mrmime](https://github.com/mirage/mrmime "mrmime project") libraries and use [facteur](https://github.com/dinosaure/facteur "facteur email sending tool") as starting point.

## License

Copyright (c) 2020 Miko Nieminen

Distributed under the MIT License.
