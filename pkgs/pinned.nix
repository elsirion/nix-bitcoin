# This file is generated by ../helper/update-flake.nix
pkgs: pkgsUnstable:
{
  inherit (pkgs)
    lndconnect;

  inherit (pkgsUnstable)
    bitcoin
    bitcoind
    btcpayserver
    charge-lnd
    clightning
    electrs
    elementsd
    extra-container
    hwi
    lightning-loop
    lightning-pool
    lnd
    nbxplorer;

  inherit pkgs pkgsUnstable;
}
