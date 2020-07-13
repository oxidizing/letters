# &#9993; Letters &middot; [![CircleCI](https://circleci.com/gh/oxidizing/letters.svg?style=shield)](https://circleci.com/gh/oxidizing/letters) ![GitHub](https://img.shields.io/github/license/oxidizing/letters)

Letters is a library for creating and sending emails over SMTP using [Lwt](https://github.com/ocsigen/lwt).

## Setup

``` shell
opam switch create . ocaml-base-compiler.4.08.1
eval $(opam env)
opam install --deps-only -y . --with-test
```

## Build

``` shell
dune build
```

## Run Tests

First create *ethereal.email* account and store account details
``` shell
curl -d '{ "requestor": "letters", "version": "0.1.0" }' "https://api.nodemailer.com/user" -X POST -H "Content-Type: application/json" > ethereal_account.json
```

Currently using `ethereal.email` service requires non-released version of `colombe` and
you need to check out the project, commit `edf757c58fce58c170c63e8a92d3bc81fe4d32ff` contains the needed fix. Then the version with the fix needs to be pinned in the build env:

``` shell
cd /path/to/colombe
opam switch /path/to/letters
# Follow instructions to evaluate the environment
git switch --detach edf757c58fce58c170c63e8a92d3bc81fe4d32ff
opam pin .
# Finally, return back to letters project
cd /path/to/letters
```

Then execute the tests

``` shell
dune test
```

And finally review that the email is correctly generated in the service:
- login to https://ethereal.email/login using credentials from the `ethereal_account.json`
- check the content of messages: https://ethereal.email/messages

## Credits

This project is build on [colombe](https://github.com/mirage/colombe "colombe project") and [mrmime](https://github.com/mirage/mrmime "mrmime project") libraries and use [facteur](https://github.com/dinosaure/facteur "facteur email sending tool") as starting point.

## License

Copyright (c) 2020 Miko Nieminen

Distributed under the MIT License.
