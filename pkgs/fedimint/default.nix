{ stdenv, lib, rustPlatform, fetchurl, pkgs, fetchFromGitHub, openssl, pkg-config, perl, clang, jq }:

rustPlatform.buildRustPackage rec {
  pname = "fedimint";
  version = "master";
  nativeBuildInputs = [ pkg-config perl openssl clang jq pkgs.mold ];
  OPENSSL_DIR = "${pkgs.openssl.dev}";
  OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";  
  LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
  src = builtins.fetchGit {
    url = "https://github.com/fedimint/fedimint";
    ref = "master";
    rev = "a26e14b58b2b9f31153546909ecf8516e5ad182f";
  };
  cargoSha256 = "sha256-BBKIc4JbN1mssdmvBKfvlhqgOQLOvXe9CEhfKqbwn9U=";
  meta = with lib; {
    description = "Federated Mint Prototype";
    homepage = "https://github.com/fedimint/fedimint";
    license = licenses.mit;
    maintainers = with maintainers; [ wiredhikari ];
  };
}