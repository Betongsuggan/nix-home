{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.my.postgresql;
  pg = config.services.postgresql;
in
{
  options.my.postgresql = {
    refreshCollations = mkOption {
      type = types.bool;
      default = pg.enable;
      defaultText = literalExpression "config.services.postgresql.enable";
      description = ''
        Before NixOS's own database setup runs, reindex and refresh every
        database whose recorded collation version differs from the one the
        running C library provides. A glibc upgrade (every NixOS release)
        changes text sort order: PostgreSQL then warns on each connection,
        and refuses to create new databases from `template1` at all. The
        check is a catalog query and costs nothing on a normal boot.
      '';
    };
  };

  config = mkIf cfg.refreshCollations {
    systemd.services.postgresql-collation-refresh = {
      description = "Reindex and refresh databases whose collation version changed";
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];
      before = [ "postgresql-setup.service" ];
      wantedBy = [ "postgresql-setup.service" ];
      path = [ pg.finalPackage ];
      environment.PGPORT = toString pg.settings.port;
      serviceConfig = {
        Type = "oneshot";
        User = "postgres";
        Group = "postgres";
      };
      script = ''
        for _ in $(seq 60); do pg_isready -q && break; sleep 1; done

        psql -d postgres -XAt -v ON_ERROR_STOP=1 -c "
          SELECT datname FROM pg_database
          WHERE datallowconn
            AND datcollversion IS DISTINCT FROM pg_database_collation_actual_version(oid)" \
        | while read -r db; do
          echo "collation version of '$db' is stale: reindexing and refreshing"
          # REINDEX DATABASE only works on the connected database
          psql -d "$db" -X -v ON_ERROR_STOP=1 -c "REINDEX DATABASE \"$db\";"
          psql -d postgres -X -v ON_ERROR_STOP=1 -c "ALTER DATABASE \"$db\" REFRESH COLLATION VERSION;"
        done
      '';
    };
  };
}
