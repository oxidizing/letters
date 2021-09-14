.PHONY: deps
deps: ## Install development dependencies
	opam install --deps-only --with-test --with-doc -y .
	eval $(opam env)

.PHONY: create_switch
create_switch:
	opam switch create . --no-install --locked
	eval $(opam env)

.PHONY: build
build:
	opam exec -- dune build @install

.PHONY: clean
clean:
	opam exec -- dune clean

.PHONY: test-all
test-all:
	curl -s -d '{ "requestor": "letters", "version": "0.1.0" }' "https://api.nodemailer.com/user" -X POST -H "Content-Type: application/json" > ethereal_account.json
	opam exec -- dune runtest --force --no-buffer test
