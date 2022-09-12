{ config, lib, pkgs, ... }:

with lib;
let
  options.services.fedimint-helper = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        LN faucet
      '';
    };
    connect = mkOption {
      type = types.str;
      description = "Connect string of the federation";
    };
    address = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address to listen for RPC connections.";
    };
    port = mkOption {
      type = types.port;
      default = 5000;
      description = "Port to listen for RPC connections.";
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
      default = config.nix-bitcoin.pkgs.fedimint-helper;
      defaultText = "config.nix-bitcoin.pkgs.fedimint-helper";
      description = "The package providing fedimint helper executable.";
    };
  };

  cfg = config.services.fedimint-helper;
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
      };
      serviceConfig = nbLib.defaultHardening // {
        WorkingDirectory = "${cfg.package}/bin";
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
