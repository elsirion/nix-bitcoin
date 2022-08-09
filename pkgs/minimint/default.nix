{ stdenv, lib, rustPlatform, fetchurl, pkgs, fetchFromGitHub, openssl, pkg-config, perl, clang, jq }:

rustPlatform.buildRustPackage rec {
  pname = "minimint";
  version = "2022-08-signet";
  nativeBuildInputs = [ pkg-config perl openssl clang jq ];
  OPENSSL_DIR = "${pkgs.openssl.dev}";
  OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";  
  LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
   src = builtins.fetchGit {
  url = "https://github.com/fedimint/minimint";
  ref = "2022-08-signet";
  rev = "a968f38ce5514f13ea7c908b4d881892d116211b";
  };
  cargoSha256 = "sha256-Ao44FtmngLAODLWElx/L3VOc/QekX+XKdcy4RhUHkfs=";
  meta = with lib; {
    description = "Federated Mint Prototype";
    homepage = "https://github.com/fedimint/minimint";
    license = licenses.mit;
    maintainers = with maintainers; [ wiredhikari ];
  };
}