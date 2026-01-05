# db/mariadb-app

Creates a MariaDB database, app user, optional admin users, and stores credentials in Vault KV v2 using the MySQL provider.

```hcl
module "kobchocen_api_db" {
  source = "../../modules/db/mariadb-app"

  database_name = "kobchocen_api"
  app_user_name = "kobchocen_api"
  database_character_set = "utf8mb4"
  database_collation     = "utf8mb4_general_ci"

  environment = "dev"
  app_group   = "kobchocen"
  app_name    = "api"

  db_host = "mariadb.apps.svc.cluster.local"

  admin_users = {
    "admin-kobchocen-dev" = {
      scope = "database"
    }
  }
}
```

Vault storage:
- App user secret path: `${vault_app_secret_prefix}/databases/mariadb`
- Admin secret path: `${vault_admin_secret_prefix}/admins/mariadb/<admin_user>`

Shared admin credentials:
- Override `vault_admin_secret_prefix` (for example `kobchocen/shared`) and create the admin user only once (e.g. in `prod`).
- This stores the admin secret at `apps/kobchocen/shared/admins/mariadb/<admin_user>`.

Existing admin users:
- Use `existing_admin_users` to apply grants without creating the user.
- Useful when you want the same admin across multiple databases without re-creating the account.

Ensure the KV v2 mount (default `apps`) exists before applying this module.
