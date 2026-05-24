{
  config,
  lib,
  pkgs,
  options,
  ...
}:

with lib;

let
  createService =
    name: cfg:
    let
      exportString = builtins.concatStringsSep "\n" (
        map (key: "export ${key}=\"${cfg.args.${key}}\"") (builtins.attrNames cfg.args)
      );

      envFile = builtins.toFile "${name}.env" ''
        ${exportString}
      '';
    in
    mkIf cfg.enable {
      "${cfg.serviceName}" = {
        description = "${name} Docker Compose Service";
        wants = [ "docker.service" ];
        wantedBy = [ "multi-user.target" ];
        restartTriggers = [ "${config.homeserver.env.repoDir}/${cfg.dir}/${cfg.file}" ];
        restartIfChanged = true;

        serviceConfig = {
          Restart = "always";
          RestartSec = 5;

          WorkingDirectory = "${cfg.dir}";

          ExecStart = "${pkgs.docker}/bin/docker compose --env-file ${envFile} -f ${config.homeserver.env.repoDir}/${cfg.dir}/${cfg.file} up --build";
          ExecReload = "${exportString} ${pkgs.docker}/bin/docker compose --build --env-file ${envFile} -f ${config.homeserver.env.repoDir}/${cfg.dir}/${cfg.file} up --build -d";
          ExecStop = "${pkgs.docker}/bin/docker compose -f ${config.homeserver.env.repoDir}/${cfg.dir}/${cfg.file} down";
        };
      };
    };
in
{
  options.homeserver.env = mkOption {
    type = types.submodule {
      options = {
        repoDir = mkOption {
          type = types.str;
          description = "Root directory where docker-compose services are stored";
          example = "/root/services";
        };
      };
    };
    description = "Homeserver environment configuration";
    default = { };
  };

  options.homeserver.services.docker-compose-stack = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to enable this docker-compose service";
          };
          dir = mkOption {
            type = types.str;
            description = "Path to the directory of docker-compose.yml file";
          };
          file = mkOption {
            type = types.str;
            default = "docker-compose.yml";
            description = "Name of the docker-compose.yml file";
          };
          serviceName = mkOption {
            type = types.str;
            description = "Name of the systemd service";
          };
          args = mkOption {
            type = types.attrsOf types.str;
            description = "Environment variables to pass to docker-compose";
            default = { };
          };
        };
      }
    );
    description = "Docker Compose Services";
    default = { };
  };

  config = mkIf (config.homeserver.services.docker-compose-stack != { }) {
    systemd.services = (
      foldl' recursiveUpdate { } (
        (mapAttrsToList createService config.homeserver.services.docker-compose-stack)
      )
    );
  };
}
