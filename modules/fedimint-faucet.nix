{ config, lib, pkgs, ... }:

with lib;
let
  options.services.fedimint-faucet = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Fedimint signet LN faucet
      '';
    };
    connect = mkOption {
      type = types.str;
      description = "Connect string of the federation";
    };
    version = mkOption {
      type = types.str;
      description = "Deployed version hash of fedimint";
    };
    user = mkOption {
      type = types.str;
      default = "clightning";
      description = "The user as which to run fedimint.";
    };
    group = mkOption {
      type = types.str;
      default = cfg.user;
      description = "The group as which to run fedimint.";
    };
    package = mkOption {
      type = types.package;
      default = config.nix-bitcoin.pkgs.fedimint-faucet;
      defaultText = "config.nix-bitcoin.pkgs.fedimint-faucet";
      description = "The package providing fedimint helper executable.";
    };
  };

  cfg = config.services.fedimint-faucet;
  nbLib = config.nix-bitcoin.lib;
  nbPkgs = config.nix-bitcoin.pkgs;
  runAsUser = config.nix-bitcoin.runAsUserCmd;
  clnrpc = "${config.services.clightning.networkDir}/lightning-rpc";
in {
  inherit options;

  config = mkIf cfg.enable {
    systemd.services.fedimint-helper = {
      wantedBy = [ "multi-user.target" ];
      requires = [ "clightning.service" ];
      after = [ "clightning.service" ];
      environment = {
        RPC_SOCKET = clnrpc;
        CONNECT_STRING = cfg.connect;
        DEPLOYED_VERSION = cfg.version;
      };
      serviceConfig = nbLib.defaultHardening // {
        ExecStart = "${cfg.package}/bin/faucet.py";
        User = cfg.user;
        Group = cfg.group;
        Restart = "on-failure";
        RestartSec = "10s";
      } // nbLib.allowAllIPAddresses;
    };
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
    };
    users.groups.${cfg.group} = {};
    nix-bitcoin.operator = {
      groups = [ cfg.group ];
      allowRunAsUsers = [ cfg.user ];
    };
  };
}
