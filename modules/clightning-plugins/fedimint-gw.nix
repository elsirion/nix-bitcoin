{ config, lib, pkgs, ... }:

with lib;
let cfg = config.services.clightning.plugins.fedimint-gw; in
{
  options.services.clightning.plugins.fedimint-gw = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable the fedimint lightning gateway (clightning plugin).
      '';
    };
    dataDir = mkOption {
      type = types.str;
      default = "${config.services.clightning.dataDir}/fedimint-gw";
      description = ''
        Directory that will contain the config and database for the gateway plugin.
      '';
    };
    package = mkOption {
      type = types.package;
      default = config.nix-bitcoin.pkgs.minimint;
      defaultText = "config.nix-bitcoin.pkgs.minimint";
      description = "The package providing the lightning gateway binaries.";
    };
  };

  config = mkIf cfg.enable {
    services.clightning.extraConfig = ''
      plugin=${cfg.package}/bin/ln_gateway
      minimint-cfg=${cfg.dataDir}
    '';
  };
}
