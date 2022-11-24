{ config, lib, pkgs, ... }:

with lib;
let
  options.services.fedimint = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable Fedimint, a federated Chaumian e-cash mint backed
        by bitcoin with deposits and withdrawals that can occur on-chain
        or via Lightning.
      '';
    };
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/fedimint";
      description = "The data directory for fedimint.";
    };
    user = mkOption {
      type = types.str;
      default = "fedimint";
      description = "The user as which to run fedimint.";
    };
    group = mkOption {
      type = types.str;
      default = cfg.user;
      description = "The group as which to run fedimint.";
    };
    package = mkOption {
      type = types.package;
      default = config.nix-bitcoin.pkgs.fedimint;
      defaultText = "config.nix-bitcoin.pkgs.fedimint";
      description = "The package providing fedimint binaries.";
    };
  };

  cfg = config.services.fedimint;
  nbLib = config.nix-bitcoin.lib;
  nbPkgs = config.nix-bitcoin.pkgs;
  runAsUser = config.nix-bitcoin.runAsUserCmd;
  secretsDir = config.nix-bitcoin.secretsDir;
  bitcoind = config.services.bitcoind;

in {
  inherit options;

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    services.bitcoind = {
      enable = true;
    };
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0770 ${cfg.user} ${cfg.group} - -"
    ];
    systemd.services.fedimint = {
      wantedBy = [ "multi-user.target" ];
      requires = [ "bitcoind.service" ];
      after = [ "bitcoind.service" ];
      serviceConfig = nbLib.defaultHardening // {
        WorkingDirectory = cfg.dataDir;
        ExecStart = ''
          ${cfg.package}/bin/fedimintd ${cfg.dataDir} supersecurepassword 5001
        '';
        User = cfg.user;
        Group = cfg.group;
        Restart = "on-failure";
        RestartSec = "10s";
        ReadWritePaths = cfg.dataDir;
      } // nbLib.allowAllIPAddresses;
    };
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      extraGroups = [ "bitcoinrpc-public" ];
    };
    users.groups.${cfg.group} = {};
    nix-bitcoin.operator = {
      groups = [ cfg.group ];
      allowRunAsUsers = [ cfg.user ];
    };
  };
}
