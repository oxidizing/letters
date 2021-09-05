# &#9993; Letters &middot; ![GitHub](https://img.shields.io/github/license/oxidizing/letters)

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

CA certificate auto-detection is done once initially when you call `Letters.send`. If the CA certificate auto-detection does not work for you (whether you plan on moving the CA certificate after calling `Letters.send` initially or whether the detection simply fails on your system), you can define path to a certificate bundle or to a single PEM encoded certificate, or you can define path to a folder containing multiple PEM encoded certificate files.

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
3. `Mixed`, multipart/alternative containing both: plain text and HTML segments

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
let subject = "Plain text only test email" in
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

Example of building an email with plain text and HTML segments:

``` ocaml
let sender = "harry@example.com" in
let recipients =
  [
    To "larry@example.com";
    Cc "bill@example.com";
    Bcc "dave@example.com";
  ]
in
let subject = "Mixed plain text / HTML test email" in
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

Because these tests are somewhat slow and fragile, you need to run them manually. Execution of these tests depends on test accounts on *ethereal.email* and *mailtrap.io*. Before execution, you need to create configuration files with authentication credentials for each service. You can generate these configuration files by using the shell command snippets given below, but for those you need to have `jq` application installed. If you don't have it or you don't want to install it, you can also create `ethereal_account.json` and `mailtrap_account.json` files manually. Both files have the following format:

``` json-with-comments
{
  "host": "smtp.ethereal.email or smtp.mailtrap.io",
  "port": 587,
  "username": "username for SMTP authentication",
  "password": "password for SMTP authentication",
  "secure": false // we will always use encryption, but `false` causes use of STARTTLS
}
```

To create temporary *ethereal.email* account and store the account details, you can execute the following one-liner:

``` shell
curl -s -d '{ "requestor": "letters", "version": "dev" }' "https://api.nodemailer.com/user" -X POST -H "Content-Type: application/json" | jq '{ hostname: .smtp.host, port: .smtp.port, secure: false, username: .user, password: .pass, }'> ethereal_account.json
```

For *mailtrap.io*, you need to create a personal account first and get the API key:
- [signup](https://mailtrap.io/register/signup?ref=header)
- [copy API token from Settings](https://mailtrap.io/settings)

The configuration file you can create with following steps:
- create environment variable containing your API token: `export MAILTRAP_API_TOKEN=<API token>`
- run the following one-liner in terminal to create the configuration file:

``` shell
curl -s -H "Authorization: Bearer ${MAILTRAP_API_TOKEN}" "https://mailtrap.io/api/v1/inboxes" | jq '.[0] | { hostname: .domain, port: .smtp_ports[2], secure: false, username: .username, password: .password }' > mailtrap_account.json
```

Now you are ready to execute these tests. You can run them with the following command:

``` shell
dune build @runtest-all
```

Finally review that all emails are correctly received in *ethreal.email*:
- login to https://ethereal.email/login using credentials from the `ethereal_account.json`
- check the content of new messages: https://ethereal.email/messages

Also check that you can find all emails in the inbox in *mailtrap.io*:
- login to [mailtrap.io](https://mailtrap.io/signin) using your personal credentials
- select the first inbox (unless you use another one), from [inboxes](https://mailtrap.io/inboxes)
- check the content of new messages

## Credits

This project is build on [colombe](https://github.com/mirage/colombe "colombe project") and [mrmime](https://github.com/mirage/mrmime "mrmime project") libraries and use [facteur](https://github.com/dinosaure/facteur "facteur email sending tool") as starting point.

## License

Copyright (c) 2020 Miko Nieminen

Distributed under the MIT License.
