{ stdenv, lib, rustPlatform, fetchurl, pkgs, fetchFromGitHub, openssl, pkg-config, perl, clang, jq }:

rustPlatform.buildRustPackage rec {
  pname = "fedimint";
  version = "2022-08-signet";
  nativeBuildInputs = [ pkg-config perl openssl clang jq ];
  OPENSSL_DIR = "${pkgs.openssl.dev}";
  OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";  
  LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
 src = builtins.fetchGit {
    url = "https://github.com/elsirion/fedimint";
    ref = "2022-08-signet";
    rev = "54bbc6693802c43172d809059bd521c370f2b6d8";
  };
  cargoSha256 = "sha256-AQF0gq7EbAX2MVu8piJfF7UX3O5zuvRBwuPpJ6t15tQ=";
  meta = with lib; {
    description = "Federated Mint Prototype";
    homepage = "https://github.com/fedimint/fedimint";
    license = licenses.mit;
    maintainers = with maintainers; [ wiredhikari ];
  };
}