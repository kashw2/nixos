{ lib, ... }:
{
  config.flake.lib.telemetryLogStatements =
    { config }:
    let
      arrUnits = map (name: "${name}.service") (
        lib.filter (name: config.services.${name}.enable or false) [
          "prowlarr"
          "sonarr"
          "radarr"
          "bazarr"
          "flaresolverr"
        ]
      );
      unitIs = unit: ''log.attributes["unit"] == "${unit}"'';
      unitMatches = pattern: ''IsMatch(log.attributes["unit"], "${pattern}")'';
      serviceGroups = [
        {
          name = "Alloy";
          matches = map unitIs [ "alloy.service" ];
        }
        {
          name = "Node Exporter";
          matches = map unitIs [ "prometheus-node-exporter.service" ];
        }
        {
          name = "ClickHouse";
          matches = map unitIs [ "clickhouse.service" ];
        }
        {
          name = "Auditd";
          matches = map unitIs [
            "auditd.service"
            "audit-rules-nixos.service"
          ];
        }
        {
          name = "Systemd";
          matches =
            map unitIs [
              "init.scope"
              "user-session.scope"
              "dbus-broker.service"
              "nscd.service"
              "fstrim.service"
            ]
            ++ map unitMatches [
              "^systemd-"
              "^user@"
            ];
        }
        {
          name = "OneUptime";
          matches = map unitIs [
            "oneuptime-app.service"
            "oneuptime-probe.service"
            "oneuptime-runner.service"
          ];
        }
        {
          name = "PostgreSQL";
          matches = map unitIs [
            "postgresql.service"
            "postgresql-setup.service"
          ];
        }
        {
          name = "Tailscale";
          matches = map unitIs [
            "tailscaled.service"
            "tailscaled-autoconnect.service"
          ];
        }
        {
          name = "Nix";
          matches = map unitIs [
            "nix-daemon.service"
            "nix-gc.service"
          ];
        }
        {
          name = "Logrotate";
          matches = map unitIs [
            "logrotate.service"
            "logrotate-checkconf.service"
          ];
        }
        {
          name = "Media";
          matches = map unitIs (
            [
              "jellyfin.service"
              "flood.service"
            ]
            ++ arrUnits
          );
        }
      ];
      groupStatements = map (
        group:
        ''set(resource.attributes["service.name"], "${group.name}") where (${lib.concatStringsSep " or " group.matches})''
        + lib.concatMapStrings (unit: " and log.attributes[\"unit\"] != \"${unit}\"") (group.exclude or [ ])
      ) (lib.filter (group: group.matches != [ ]) serviceGroups);
      facilityNames = [
        "kern"
        "user"
        "mail"
        "daemon"
        "auth"
        "syslog"
        "lpr"
        "news"
        "uucp"
        "cron"
        "authpriv"
        "ftp"
        "ntp"
        "security"
        "console"
        "solaris-cron"
        "local0"
        "local1"
        "local2"
        "local3"
        "local4"
        "local5"
        "local6"
        "local7"
      ];
      facilityStatements = lib.imap0 (
        num: name:
        ''set(log.attributes["facility"], "${name}") where log.attributes["facility"] == "${toString num}"''
      ) facilityNames;
    in
    [
      ''set(resource.attributes["service.name"], "Auditd") where log.attributes["transport"] == "audit"''
    ]
    ++ groupStatements
    ++ [
      ''set(resource.attributes["service.name"], log.attributes["unit"]) where resource.attributes["service.name"] == nil and log.attributes["unit"] != nil''
      ''set(resource.attributes["service.name"], log.attributes["job"]) where resource.attributes["service.name"] == nil and log.attributes["job"] != nil''
      ''set(resource.attributes["host.name"], log.attributes["hostname"]) where resource.attributes["host.name"] == nil and log.attributes["hostname"] != nil''
    ]
    ++ facilityStatements
    ++ [
      ''set(log.severity_text, log.attributes["level"]) where log.attributes["level"] != nil''
      ''set(log.severity_number, SEVERITY_NUMBER_FATAL) where log.attributes["level"] == "emerg" or log.attributes["level"] == "alert" or log.attributes["level"] == "crit"''
      ''set(log.severity_number, SEVERITY_NUMBER_ERROR) where log.attributes["level"] == "error" or log.attributes["level"] == "err"''
      ''set(log.severity_number, SEVERITY_NUMBER_WARN) where log.attributes["level"] == "warning" or log.attributes["level"] == "warn"''
      ''set(log.severity_number, SEVERITY_NUMBER_INFO) where log.attributes["level"] == "notice" or log.attributes["level"] == "info"''
      ''set(log.severity_number, SEVERITY_NUMBER_DEBUG) where log.attributes["level"] == "debug"''
      ''set(log.severity_text, "Warning") where log.attributes["transport"] == "audit" and IsMatch(log.body, "^AVC ")''
      ''set(log.severity_number, SEVERITY_NUMBER_WARN) where log.attributes["transport"] == "audit" and IsMatch(log.body, "^AVC ")''
      ''set(log.severity_text, "Information") where log.attributes["transport"] == "audit" and log.severity_text == ""''
      ''set(log.severity_number, SEVERITY_NUMBER_INFO) where log.attributes["transport"] == "audit" and log.severity_number == 0''
      ''set(log.cache, ParseJSON(log.body)) where log.attributes["job"] == "Nginx" and IsMatch(log.body, "^\\{")''
      ''set(log.attributes["http.request.method"], log.cache["method"]) where log.cache["method"] != nil''
      ''set(log.attributes["http.response.status_code"], log.cache["status"]) where log.cache["status"] != nil''
      ''set(log.attributes["url.path"], log.cache["path"]) where log.cache["path"] != nil''
      ''set(log.attributes["server.address"], log.cache["vhost"]) where log.cache["vhost"] != nil''
      ''set(log.attributes["client.address"], log.cache["remote_addr"]) where log.cache["remote_addr"] != nil''
      ''set(log.attributes["http.server.request.duration"], log.cache["duration"]) where log.cache["duration"] != nil''
      ''set(log.severity_text, "Information") where log.cache["status"] != nil and log.cache["status"] < 400''
      ''set(log.severity_number, SEVERITY_NUMBER_INFO) where log.cache["status"] != nil and log.cache["status"] < 400''
      ''set(log.severity_text, "Warning") where log.cache["status"] != nil and log.cache["status"] >= 400 and log.cache["status"] < 500''
      ''set(log.severity_number, SEVERITY_NUMBER_WARN) where log.cache["status"] != nil and log.cache["status"] >= 400 and log.cache["status"] < 500''
      ''set(log.severity_text, "Error") where log.cache["status"] != nil and log.cache["status"] >= 500''
      ''set(log.severity_number, SEVERITY_NUMBER_ERROR) where log.cache["status"] != nil and log.cache["status"] >= 500''
      ''set(log.severity_text, "Error") where log.attributes["job"] == "Nginx" and IsMatch(log.body, "\\[error\\]")''
      ''set(log.severity_number, SEVERITY_NUMBER_ERROR) where log.attributes["job"] == "Nginx" and IsMatch(log.body, "\\[error\\]")''
      ''set(log.severity_text, "Warning") where log.attributes["job"] == "Nginx" and IsMatch(log.body, "\\[warn\\]")''
      ''set(log.severity_number, SEVERITY_NUMBER_WARN) where log.attributes["job"] == "Nginx" and IsMatch(log.body, "\\[warn\\]")''
      ''set(log.cache, ParseJSON(log.body)) where log.attributes["unit"] == "alloy.service" and IsMatch(log.body, "^\\{")''
      ''set(log.severity_text, log.cache["level"]) where log.attributes["unit"] == "alloy.service" and log.cache["level"] != nil''
      ''set(log.severity_number, SEVERITY_NUMBER_ERROR) where log.attributes["unit"] == "alloy.service" and log.cache["level"] == "error"''
      ''set(log.severity_number, SEVERITY_NUMBER_WARN) where log.attributes["unit"] == "alloy.service" and log.cache["level"] == "warn"''
      ''set(log.severity_number, SEVERITY_NUMBER_INFO) where log.attributes["unit"] == "alloy.service" and log.cache["level"] == "info"''
      ''set(log.severity_number, SEVERITY_NUMBER_DEBUG) where log.attributes["unit"] == "alloy.service" and log.cache["level"] == "debug"''
    ];
}
