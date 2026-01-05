# db/postgres-app

Creates a PostgreSQL database, app user, optional admin users, and stores credentials in Vault KV v2.

```hcl
module "kobchocen_api_db" {
  source = "../../modules/db/postgres-app"

  database_name = "kobchocen_api"
  app_user_name = "kobchocen_api"

  environment = "dev"
  app_group   = "kobchocen"
  app_name    = "api"

  db_host = "postgresql.apps.svc.cluster.local"

  admin_users = {
    "admin-kobchocen-dev" = {
      scope = "database"
    }
  }
}
```

Vault storage:
- App user secret path: `${vault_app_secret_prefix}/databases/postgres`
- Admin secret path: `${vault_admin_secret_prefix}/admins/postgres/<admin_user>`

Ensure the KV v2 mount (default `apps`) exists before applying this module.
