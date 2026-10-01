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
      unitIs = unit: ''attributes["unit"] == "${unit}"'';
      unitMatches = pattern: ''IsMatch(attributes["unit"], "${pattern}")'';
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
              "apparmor.service"
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
        + lib.concatMapStrings (unit: " and attributes[\"unit\"] != \"${unit}\"") (group.exclude or [ ])
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
        ''set(attributes["facility"], "${name}") where attributes["facility"] == "${toString num}"''
      ) facilityNames;
    in
    [
      ''set(resource.attributes["service.name"], "Auditd") where attributes["transport"] == "audit"''
    ]
    ++ groupStatements
    ++ [
      ''set(resource.attributes["service.name"], attributes["unit"]) where resource.attributes["service.name"] == nil and attributes["unit"] != nil''
      ''set(resource.attributes["service.name"], attributes["job"]) where resource.attributes["service.name"] == nil and attributes["job"] != nil''
      ''set(resource.attributes["host.name"], attributes["hostname"]) where resource.attributes["host.name"] == nil and attributes["hostname"] != nil''
    ]
    ++ facilityStatements
    ++ [
      ''set(severity_text, attributes["level"]) where attributes["level"] != nil''
      ''set(severity_number, SEVERITY_NUMBER_FATAL) where attributes["level"] == "emerg" or attributes["level"] == "alert" or attributes["level"] == "crit"''
      ''set(severity_number, SEVERITY_NUMBER_ERROR) where attributes["level"] == "error" or attributes["level"] == "err"''
      ''set(severity_number, SEVERITY_NUMBER_WARN) where attributes["level"] == "warning" or attributes["level"] == "warn"''
      ''set(severity_number, SEVERITY_NUMBER_INFO) where attributes["level"] == "notice" or attributes["level"] == "info"''
      ''set(severity_number, SEVERITY_NUMBER_DEBUG) where attributes["level"] == "debug"''
      ''set(severity_text, "Warning") where attributes["transport"] == "audit" and IsMatch(body, "^AVC ")''
      ''set(severity_number, SEVERITY_NUMBER_WARN) where attributes["transport"] == "audit" and IsMatch(body, "^AVC ")''
      ''set(severity_text, "Information") where attributes["transport"] == "audit" and severity_text == ""''
      ''set(severity_number, SEVERITY_NUMBER_INFO) where attributes["transport"] == "audit" and severity_number == 0''
      ''set(cache, ParseJSON(body)) where attributes["job"] == "Nginx" and IsMatch(body, "^\\{")''
      ''set(attributes["http.request.method"], cache["method"]) where cache["method"] != nil''
      ''set(attributes["http.response.status_code"], cache["status"]) where cache["status"] != nil''
      ''set(attributes["url.path"], cache["path"]) where cache["path"] != nil''
      ''set(attributes["server.address"], cache["vhost"]) where cache["vhost"] != nil''
      ''set(attributes["client.address"], cache["remote_addr"]) where cache["remote_addr"] != nil''
      ''set(attributes["http.server.request.duration"], cache["duration"]) where cache["duration"] != nil''
      ''set(severity_text, "Information") where cache["status"] != nil and cache["status"] < 400''
      ''set(severity_number, SEVERITY_NUMBER_INFO) where cache["status"] != nil and cache["status"] < 400''
      ''set(severity_text, "Warning") where cache["status"] != nil and cache["status"] >= 400 and cache["status"] < 500''
      ''set(severity_number, SEVERITY_NUMBER_WARN) where cache["status"] != nil and cache["status"] >= 400 and cache["status"] < 500''
      ''set(severity_text, "Error") where cache["status"] != nil and cache["status"] >= 500''
      ''set(severity_number, SEVERITY_NUMBER_ERROR) where cache["status"] != nil and cache["status"] >= 500''
      ''set(severity_text, "Error") where attributes["job"] == "Nginx" and IsMatch(body, "\\[error\\]")''
      ''set(severity_number, SEVERITY_NUMBER_ERROR) where attributes["job"] == "Nginx" and IsMatch(body, "\\[error\\]")''
      ''set(severity_text, "Warning") where attributes["job"] == "Nginx" and IsMatch(body, "\\[warn\\]")''
      ''set(severity_number, SEVERITY_NUMBER_WARN) where attributes["job"] == "Nginx" and IsMatch(body, "\\[warn\\]")''
      ''set(cache, ParseJSON(body)) where attributes["unit"] == "alloy.service" and IsMatch(body, "^\\{")''
      ''set(severity_text, cache["level"]) where attributes["unit"] == "alloy.service" and cache["level"] != nil''
      ''set(severity_number, SEVERITY_NUMBER_ERROR) where attributes["unit"] == "alloy.service" and cache["level"] == "error"''
      ''set(severity_number, SEVERITY_NUMBER_WARN) where attributes["unit"] == "alloy.service" and cache["level"] == "warn"''
      ''set(severity_number, SEVERITY_NUMBER_INFO) where attributes["unit"] == "alloy.service" and cache["level"] == "info"''
      ''set(severity_number, SEVERITY_NUMBER_DEBUG) where attributes["unit"] == "alloy.service" and cache["level"] == "debug"''
    ];
}
