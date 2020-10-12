build:
	opam exec -- dune build @install

clean:
	opam exec -- dune clean

test-all:
	curl -s -d '{ "requestor": "letters", "version": "0.1.0" }' "https://api.nodemailer.com/user" -X POST -H "Content-Type: application/json" > ethereal_account.json
	opam exec -- dune runtest --force --no-buffer test
