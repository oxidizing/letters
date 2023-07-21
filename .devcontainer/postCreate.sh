#!/bin/sh

# immediately when a command fails and print each command
set -ex

# When possible to create cached docker volume,
sudo chown -R opam: _build

opam init -a --shell=zsh

# get newest opam packages
opam remote remove --all default
opam remote add default https://opam.ocaml.org

opam pin add -yn letters .
opam depext -y letters

# install opam packages used for vscode ocaml platform package
# e.g. when developing with emax, add also: utop merlin ocamlformat
opam install -y ocaml-lsp-server
make deps
