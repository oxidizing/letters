build:
	dune build @install

clean:
	dune clean

test-all:
	curl -s -d '{ "requestor": "letters", "version": "0.1.0" }' "https://api.nodemailer.com/user" -X POST -H "Content-Type: application/json" > ethereal_account.json
	dune runtest --force --no-buffer test
