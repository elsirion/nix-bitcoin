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
      txindex = true;
    };
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0770 ${cfg.user} ${cfg.group} - -"
    ];
    systemd.services.fedimint = {
      wantedBy = [ "multi-user.target" ];
      requires = [ "bitcoind.service" ];
      after = [ "bitcoind.service" ];
      preStart = ''
        if [ -f "${cfg.dataDir}/server-0.json" ]; then
          exit 0
        fi
        ${cfg.package}/bin/configgen ${cfg.dataDir} 1 4000 5000 1 10 100 1000 10000 100000 1000000
        sed -i -e "s/127.0.0.1:18443/${nbLib.addressWithPort bitcoind.rpc.address bitcoind.rpc.port}/g" ${cfg.dataDir}/server-0.json
        sed -i -e 's/user": "bitcoin"/user": "${bitcoind.rpc.users.public.name}"/g' ${cfg.dataDir}/server-0.json
        PASS=$(cat ${secretsDir}/bitcoin-rpcpassword-public)
        sed -i -e "s/bitcoin/$PASS/g" ${cfg.dataDir}/server-0.json
      '';
      serviceConfig = nbLib.defaultHardening // {
        WorkingDirectory = cfg.dataDir;
        ExecStart = ''
          ${cfg.package}/bin/fedimintd ${cfg.dataDir}/server-0.json ${cfg.dataDir}/mint-0.db
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
