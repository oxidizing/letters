with import <nixpkgs> { };

mkShell {
  buildInputs = [ zlib.dev zlib.out zlib zlib.all gmp gmp.dev pkgconfig openssl ];
  shellHook = "eval $(opam env)";
}
