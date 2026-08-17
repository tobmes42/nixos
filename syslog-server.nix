{ config, lib, pkgs, ... }:

let
  cfg = config.services.syslog-server;
in
{
  options.services.syslog-server.enable = lib.mkEnableOption "Syslog-Empfaenger (Remote-Logs der OPNsense / Unbound empfangen)";

  config = lib.mkIf cfg.enable {
    services.rsyslogd = {
      enable = true;
      extraConfig = ''
        module(load="imudp")
        input(type="imudp" port="514")

        module(load="imtcp")
        input(type="imtcp" port="514")

        # Unbound-DNS-Queries der OPNsense (durchsuchbar per grep/zgrep)
        if (($msg contains "unbound") and ($msg contains "info:")) then {
            action(type="omfile" file="/var/log/dns/queries.log" createDirs="on")
            stop
        }
        # Sonstige Remote-Syslog-Meldungen
        if (($fromhost-ip != "127.0.0.1") and ($fromhost-ip != "::1")) then {
            action(type="omfile" file="/var/log/remote/all.log" createDirs="on")
            stop
        }
      '';
    };

    services.logrotate = {
      enable = true;
      settings.opnsense = {
        frequency = "daily";
        rotate = 365;
        compress = true;
        dateext = true;
        files = [
          "/var/log/dns/queries.log"
          "/var/log/remote/all.log"
        ];
      };
    };

    networking.firewall.allowedTCPPorts = [ 514 ];
    networking.firewall.allowedUDPPorts = [ 514 ];
  };
}
