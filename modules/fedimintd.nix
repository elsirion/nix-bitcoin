{ config, lib, pkgs, ... }:

with lib;
let
  fedimint-pkg = (import
      (
        fetchTarball {
          url = "https://github.com/edolstra/flake-compat/archive/b4a34015c698c7793d592d66adbab377907a2be8.tar.gz";
          sha256 = "sha256:1qc703yg0babixi6wshn5wm2kgl5y1drcswgszh4xxzbrwkk9sv7";
        }
      )
      { src = fetchGit {
          url = "https://github.com/fedimint/fedimint/";
          ref = "refs/tags/v0.1.0";
          rev = "6361d2ea0daf59f5114b698218065ea92353e387";
        };
      }
    ).defaultNix.packages.x86_64-linux.default;

  cfg = config.services.fedimintd;
  startScript = (pkgs.writeShellScriptBin "fedimintd-start" ''
    set -euo pipefail

    BTC_RPC_PASSWORD="$(cat ${config.nix-bitcoin.secretsDir}/bitcoin-rpcpassword-public)"

    ${cfg.extraPreStartScript}
    ${pkgs.coreutils}/bin/env \
      RUST_LOG="${cfg.logEnv}" \
      RUST_BACKTRACE=1 \
      FM_BITCOIND_RPC="${cfg.bitcoindRpcAddr}" \
      FM_BIND_P2P="${cfg.p2pBind}" \
      FM_BIND_API="${cfg.apiBind}" \
      FM_BITCOIN_RPC_KIND=bitcoind \
      FM_BITCOIN_RPC_URL="public:$BTC_PRC_PASSWORD@${cfg.bitcoindRpcAddr}" \
      FM_P2P_URL="${cfg.p2pUrl}" \
      FM_API_URL="${cfg.apiUrl}" \
    ${cfg.package}/bin/fedimintd \
      --data-dir ${cfg.dataDir}
  '');

  nbLib = config.nix-bitcoin.lib;
  secretsDir = config.nix-bitcoin.secretsDir;
  bitcoind = config.services.bitcoind;
in {
  options.services.fedimintd = {
      enable = mkEnableOption "Fedimint Guardian Server";

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/fedimint";
        description = "The data directory for fedimint.";
      };

      p2pBind = mkOption {
        type = types.str;
        default = "0.0.0.0:8173";
      };

      p2pUrl = mkOption {
        type = types.str;
        example = "fedimint://example.com:8173";
        description = "Address under which the API is publicly reachable";
      };

      apiBind = mkOption {
        type = types.str;
        default = "0.0.0.0:8174";
      };

      apiUrl = mkOption {
        type = types.str;
        example = "wss://fm-api.example.com";
        description = "Address under which the API is publicly reachable. Use `wss://` if your API is behind a TLS-enabled proxy, `ws://` if running as a plain HTTP server (insecure).";
      };

      logEnv = mkOption {
        type = types.str;
        default = "info,fedimint_server::request=debug,fedimint_client::request=debug";
        description = "Value to set RUST_LOG to";
      };

      extraPreStartScript = mkOption {
        type = types.str;
        default = "";
      };

      bitcoindRpcAddr = mkOption {
        type = types.str;
        default = "127.0.0.1:8332";
        description = "address+port under which to reach bitcoind, don't add http://";
      };

      user = mkOption {
        type = types.str;
        default = "fedimint";
        description = "The user as which to run fedimintd.";
      };

      group = mkOption {
        type = types.str;
        default = cfg.user;
        description = "The group as which to run fedimintd.";
      };

      package = mkOption {
        type = types.package;
        default = fedimint-pkg;
        description = "The package providing fedimintd binary.";
      };
    };

  config = mkIf cfg.enable {
      environment.systemPackages = [ cfg.package ];
      systemd.tmpfiles.rules = [
        "d '${cfg.dataDir}' 0770 ${cfg.user} ${cfg.group} - -"
      ];
      systemd.services.fedimint = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          WorkingDirectory = cfg.dataDir;
          ExecStart = ''
            ${startScript}/bin/fedimintd-start
          '';
          User = cfg.user;
          Group = cfg.group;
          Restart = "always";
          RestartSec = "20s";
          ReadWritePaths = cfg.dataDir;
          LimitNOFILE = "550000";
        };
      };

      users.users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        extraGroups = [ "bitcoinrpc-public" ];
      };
      users.groups.${cfg.group} = {};
    };
}
