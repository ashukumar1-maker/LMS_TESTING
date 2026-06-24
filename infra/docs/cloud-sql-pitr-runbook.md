# Cloud SQL PostgreSQL Point-in-Time Recovery (PITR) Runbook

This runbook is for recovering Cloud SQL PostgreSQL instances in this template.

Template assumptions:
- Cloud SQL instance name pattern is `${environment}-db` (for example `dev-db`, `staging-db`, `prod-db`).
- Terraform now enables automated backups and PITR in `infra/modules/gcp/database`.
- Each environment has its own GCP project (pattern: `${project_id}-${environment}`).

## 1. Prerequisites

1. Ensure you are authenticated:
   ```bash
   gcloud auth login
   gcloud auth list
   ```
2. Ensure you are in the correct project:
   ```bash
   export ENV="prod"                      # dev | staging | prod
   export PROJECT_ID="<your-project>-${ENV}"
   export SOURCE_INSTANCE="${ENV}-db"
   gcloud config set project "${PROJECT_ID}"
   ```
3. Ensure you have permissions to clone and inspect backups.
   - The account running PITR needs `cloudsql.instances.clone`.
   - To inspect retained backups, you also need backup permissions such as `cloudsql.backupRuns.list` and `cloudsql.backupRuns.get`.

## 2. Confirm PITR Is Enabled

Check the source instance backup/PITR config:

```bash
gcloud sql instances describe "${SOURCE_INSTANCE}" \
  --project="${PROJECT_ID}" \
  --format="yaml(settings.backupConfiguration)"
```

You should see:
- `enabled: true`
- `pointInTimeRecoveryEnabled: true`

## 3. Determine Valid Recovery Window

Pick the timestamp to recover to (UTC, RFC 3339). First, get the valid PITR window:

```bash
gcloud sql instances get-latest-recovery-time "${SOURCE_INSTANCE}" \
  --project="${PROJECT_ID}"
```

Choose `PITR_TIMESTAMP` between `earliestRecoveryTime` and `latestRecoveryTime`.

Example:

```bash
export PITR_TIMESTAMP="2026-02-13T18:32:00Z"
export TARGET_INSTANCE="${ENV}-db-pitr-$(date -u +%Y%m%d%H%M)"
```

## 4. PITR for a Live Instance (Primary Flow)

Create a clone restored to the chosen point in time:

```bash
gcloud sql instances clone "${SOURCE_INSTANCE}" "${TARGET_INSTANCE}" \
  --point-in-time="${PITR_TIMESTAMP}" \
  --project="${PROJECT_ID}"
```

Notes:
- Source and destination must be in the same project.
- `--point-in-time` must be UTC RFC 3339.

## 5. PITR for an Unavailable Instance (Zone Issue)

If the source zone is unavailable, restore to a different zone:

```bash
gcloud sql instances clone "${SOURCE_INSTANCE}" "${TARGET_INSTANCE}" \
  --point-in-time="${PITR_TIMESTAMP}" \
  --preferred-zone="<primary-zone>" \
  --preferred-secondary-zone="<secondary-zone>" \
  --project="${PROJECT_ID}"
```

## 6. PITR for a Deleted Instance

1. List backups in the project and filter to the deleted source instance:
   ```bash
   gcloud sql backups list \
     --project="${PROJECT_ID}" \
     --filter="instance:${SOURCE_INSTANCE}" \
     --format="table(name,instance,type,state,windowStartTime,instanceDeletionTime)"
   ```
   Use a backup row where `INSTANCE_DELETION_TIME` is populated (that indicates a deleted source instance backup), then set:
   ```bash
   export SOURCE_INSTANCE_DELETION_TIMESTAMP="<INSTANCE_DELETION_TIME>"
   export BACKUP_NAME="<NAME>"
   ```
2. Describe the selected backup (sanity check):
   ```bash
   gcloud sql backups describe "${BACKUP_NAME}" \
     --project="${PROJECT_ID}"
   ```
3. Optionally confirm PITR window for the deleted source:
   ```bash
   gcloud sql instances get-latest-recovery-time "${SOURCE_INSTANCE}" \
     --source-instance-deletion-time="${SOURCE_INSTANCE_DELETION_TIMESTAMP}" \
     --project="${PROJECT_ID}"
   ```
4. Restore deleted instance to a new clone:
   ```bash
   gcloud sql instances clone "${SOURCE_INSTANCE}" "${TARGET_INSTANCE}" \
     --point-in-time="${PITR_TIMESTAMP}" \
     --source-instance-deletion-time="${SOURCE_INSTANCE_DELETION_TIMESTAMP}" \
     --project="${PROJECT_ID}"
   ```

## 7. Track Operation and Validate Recovery

Track recent operations:

```bash
gcloud sql operations list --instance="${TARGET_INSTANCE}" --project="${PROJECT_ID}" --limit=10
```

Inspect a specific operation:

```bash
gcloud sql operations describe "<OPERATION_ID>" --project="${PROJECT_ID}"
```

After completion, validate:
1. App-critical tables/row counts.
2. Expected data state at the incident timestamp.
3. Database users/roles required by application.
4. Connectivity from the workload network path (Cloud Run / VPC path used by this template).

## 8. Cutover With Current Terraform

Reality check for this repo as-is:
- The database instance name is fixed to `${environment}-db` in Terraform.

### 8.1 What this means operationally

With current Terraform, PITR cutover to a clone must be done out-of-band (gcloud), then reconciled back to Terraform later.

Do **not** run `terraform apply` during temporary clone cutover unless you intend Terraform to switch back to `${environment}-db`.

### 8.2 Emergency cutover steps (out-of-band, current repo)

Assume:
- `SOURCE_INSTANCE="${ENV}-db"`
- `TARGET_INSTANCE` is your PITR clone
- `REGION` is the backend Cloud Run region (for this template, typically `us-west1`)
- `BACKEND_SERVICE="${ENV}-backend"`

#### Pre-cutover validation (must all pass)

If any check below fails, stop and fix the issue before proceeding with cutover.

1. Verify clone is `RUNNABLE`:
   ```bash
   test "$(gcloud sql instances describe "${TARGET_INSTANCE}" --project="${PROJECT_ID}" --format='value(state)')" = "RUNNABLE" || {
     echo "Target clone is not RUNNABLE"; exit 1;
   }
   ```
2. List database users on target clone:
   ```bash
   gcloud sql users list --instance="${TARGET_INSTANCE}" --project="${PROJECT_ID}" --format='table(name,type,host)'
   ```
3. Validate Cloud Run network-path readiness to target clone:
   ```bash
   export BACKEND_SERVICE_ACCOUNT="$(gcloud run services describe "${BACKEND_SERVICE}" --region="${REGION}" --project="${PROJECT_ID}" --format='value(spec.template.spec.serviceAccountName)')"

   gcloud run services describe "${BACKEND_SERVICE}" \
     --region="${REGION}" \
     --project="${PROJECT_ID}" \
     --format='yaml(spec.template.metadata.annotations.run.googleapis.com/vpc-access-connector,spec.template.spec.serviceAccountName,spec.template.metadata.annotations.run.googleapis.com/cloudsql-instances)'

   export SQL_CLIENT_CONDITION="$(gcloud projects get-iam-policy "${PROJECT_ID}" \
     --flatten='bindings[].members' \
     --filter="bindings.members:serviceAccount:${BACKEND_SERVICE_ACCOUNT} AND bindings.role:roles/cloudsql.client" \
     --format='value(bindings.condition.expression)')"

   if ! echo "${SQL_CLIENT_CONDITION}" | grep -Fq "${TARGET_INSTANCE}"; then
     echo "WARNING: Expected for PITR clones: service account is scoped to SOURCE_INSTANCE, not TARGET_INSTANCE."
     echo "Grant temporary clone access, then re-run this pre-cutover check:"
     gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
       --member="serviceAccount:${BACKEND_SERVICE_ACCOUNT}" \
       --role="roles/cloudsql.client" \
       --condition="expression=resource.name == \"projects/${PROJECT_ID}/instances/${TARGET_INSTANCE}\",title=pitr_clone_access_${ENV},description=Temporary Cloud SQL clone access for PITR cutover"

     export SQL_CLIENT_CONDITION="$(gcloud projects get-iam-policy "${PROJECT_ID}" \
       --flatten='bindings[].members' \
       --filter="bindings.members:serviceAccount:${BACKEND_SERVICE_ACCOUNT} AND bindings.role:roles/cloudsql.client" \
       --format='value(bindings.condition.expression)')"
   fi

   echo "${SQL_CLIENT_CONDITION}" | grep -Fq "${TARGET_INSTANCE}" || {
     echo "Backend service account still not scoped for TARGET_INSTANCE (${TARGET_INSTANCE}); stop and fix IAM before cutover."; exit 1;
   }
   ```
4. Run application schema + critical-table validation queries in Cloud SQL Studio against target:
   - Cloud SQL Studio is browser-based and runs SQL only (not bash):
     https://cloud.google.com/sql/docs/postgres/manage-data-using-studio
   Then in Cloud Console (Cloud SQL Studio):
   - Open Cloud SQL Studio for `${TARGET_INSTANCE}`.
   - Connect with an application SQL user for this environment and the expected application database.
   - Run:
     ```sql
     SELECT current_database() AS database_name, current_user AS db_user;
     SELECT COUNT(*) AS alembic_version_rows FROM alembic_version;
     -- Replace with your app-specific critical-table checks before cutover:
     -- SELECT COUNT(*) FROM <critical_table_1>;
     -- SELECT COUNT(*) FROM <critical_table_2>;
     ```
   - Confirm results match expected post-restore state before continuing.
5. Confirm storage and tier on source and target:
   ```bash
   gcloud sql instances describe "${SOURCE_INSTANCE}" --project="${PROJECT_ID}" --format='table(name,settings.tier,settings.dataDiskSizeGb)'
   gcloud sql instances describe "${TARGET_INSTANCE}" --project="${PROJECT_ID}" --format='table(name,settings.tier,settings.dataDiskSizeGb)'
   ```

1. Get source/target connection names:
   ```bash
   export SOURCE_CONNECTION_NAME="$(gcloud sql instances describe "${SOURCE_INSTANCE}" --project="${PROJECT_ID}" --format='value(connectionName)')"
   export TARGET_CONNECTION_NAME="$(gcloud sql instances describe "${TARGET_INSTANCE}" --project="${PROJECT_ID}" --format='value(connectionName)')"
   ```
2. Update backend DB connection secret to point at clone connection name:
   ```bash
   export DATABASE_SECRET_ID="$(gcloud secrets list \
     --project="${PROJECT_ID}" \
     --filter="labels.environment=${ENV} AND labels.purpose=database-connection AND labels.service=backend" \
     --format="value(name)" \
     --limit=1)"
   test -n "${DATABASE_SECRET_ID}" || { echo "DB connection secret not found"; exit 1; }

   export CURRENT_DATABASE_URL="$(gcloud secrets versions access latest --secret="${DATABASE_SECRET_ID}" --project="${PROJECT_ID}")"
   export SOURCE_CONNECTION_OCCURRENCES="$(printf '%s' "${CURRENT_DATABASE_URL}" | grep -oF "${SOURCE_CONNECTION_NAME}" | wc -l | tr -d ' ')"
   test "${SOURCE_CONNECTION_OCCURRENCES}" = "1" || {
     echo "Expected SOURCE_CONNECTION_NAME to appear exactly once in CURRENT_DATABASE_URL, found ${SOURCE_CONNECTION_OCCURRENCES}."; exit 1;
   }

   export CUTOVER_DATABASE_URL="${CURRENT_DATABASE_URL/${SOURCE_CONNECTION_NAME}/${TARGET_CONNECTION_NAME}}"
   test "${CUTOVER_DATABASE_URL}" != "${CURRENT_DATABASE_URL}" || {
     echo "DATABASE_URL substitution failed: CUTOVER_DATABASE_URL did not change."; exit 1;
   }

   echo "CURRENT_DATABASE_URL=${CURRENT_DATABASE_URL}"
   echo "CUTOVER_DATABASE_URL=${CUTOVER_DATABASE_URL}"
   read -r -p "Write CUTOVER_DATABASE_URL to secret ${DATABASE_SECRET_ID}? Type 'yes' to continue: " CONFIRM_CUTOVER_SECRET_WRITE
   test "${CONFIRM_CUTOVER_SECRET_WRITE}" = "yes" || { echo "Aborted by operator."; exit 1; }

   printf '%s' "${CUTOVER_DATABASE_URL}" | gcloud secrets versions add "${DATABASE_SECRET_ID}" --data-file=- --project="${PROJECT_ID}"
   ```
3. Update Cloud Run to mount the clone Cloud SQL instance:
   ```bash
   gcloud run services update "${BACKEND_SERVICE}" \
     --region="${REGION}" \
     --project="${PROJECT_ID}" \
     --set-cloudsql-instances="${TARGET_CONNECTION_NAME}"
   ```
   Note: this creates a new Cloud Run revision. Service restart during rollout can cause a brief traffic interruption.
4. Persist original connection secret value for rollback across sessions:
   ```bash
   export ORIGINAL_DATABASE_URL_FILE="/tmp/${ENV}-original-database-url.txt"
   printf '%s' "${CURRENT_DATABASE_URL}" > "${ORIGINAL_DATABASE_URL_FILE}"
   chmod 600 "${ORIGINAL_DATABASE_URL_FILE}"
   echo "Saved CURRENT_DATABASE_URL to ${ORIGINAL_DATABASE_URL_FILE}"
   ```
5. Validate app behavior and resume writes.

Rollback (temporary cutover undo):
```bash
if [ -z "${DATABASE_SECRET_ID:-}" ]; then
  export DATABASE_SECRET_ID="$(gcloud secrets list \
    --project="${PROJECT_ID}" \
    --filter="labels.environment=${ENV} AND labels.purpose=database-connection AND labels.service=backend" \
    --format="value(name)" \
    --limit=1)"
fi
test -n "${DATABASE_SECRET_ID}" || { echo "DB connection secret not found"; exit 1; }

if [ -z "${SOURCE_CONNECTION_NAME:-}" ]; then
  export SOURCE_CONNECTION_NAME="$(gcloud sql instances describe "${SOURCE_INSTANCE}" --project="${PROJECT_ID}" --format='value(connectionName)')"
fi

if [ -z "${CURRENT_DATABASE_URL:-}" ]; then
  export ORIGINAL_DATABASE_URL_FILE="/tmp/${ENV}-original-database-url.txt"
  test -f "${ORIGINAL_DATABASE_URL_FILE}" || { echo "CURRENT_DATABASE_URL unset and ${ORIGINAL_DATABASE_URL_FILE} not found."; exit 1; }
  export CURRENT_DATABASE_URL="$(cat "${ORIGINAL_DATABASE_URL_FILE}")"
fi

printf '%s' "${CURRENT_DATABASE_URL}" | gcloud secrets versions add "${DATABASE_SECRET_ID}" --data-file=- --project="${PROJECT_ID}"
gcloud run services update "${BACKEND_SERVICE}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --set-cloudsql-instances="${SOURCE_CONNECTION_NAME}"
```

### 8.3 Restoring Terraform control after the incident

1. Return runtime configuration to canonical Terraform-managed DB (`${ENV}-db`) using rollback steps above.
2. If clone has newer/correct data, migrate data from clone back to canonical instance before rollback.
3. Run `terraform plan` / `terraform apply` from `infra/environments/${ENV}` to verify state matches desired config again.

Important:
- Current Terraform cannot keep a differently named clone as the long-term primary without code changes.
- If canonical instance name was deleted and cannot be reused immediately, keep operations out-of-band until Terraform is updated to support a different primary instance name.

## 9. Operational Checklist

- [ ] Incident time identified in UTC.
- [ ] PITR window confirmed (`earliestRecoveryTime`, `latestRecoveryTime`).
- [ ] Correct source instance and project confirmed.
- [ ] Clone restore command executed.
- [ ] Restore operation reached `DONE`.
- [ ] Data integrity checks passed.
- [ ] Cutover plan executed and verified.
- [ ] Post-incident notes captured (timestamp, operation ID, root cause).

## References

- [Configure point-in-time recovery (PITR) for Cloud SQL PostgreSQL](https://cloud.google.com/sql/docs/postgres/backup-recovery/configure-pitr)
- [Perform point-in-time recovery (PITR) for Cloud SQL PostgreSQL](https://cloud.google.com/sql/docs/postgres/backup-recovery/pitr)
- [Manage backups for deleted Cloud SQL PostgreSQL instances](https://cloud.google.com/sql/docs/postgres/backup-recovery/manage-backups-deleted-instance)
- [gcloud sql instances clone](https://docs.cloud.google.com/sdk/gcloud/reference/sql/instances/clone)
- [gcloud sql instances get-latest-recovery-time](https://docs.cloud.google.com/sdk/gcloud/reference/sql/instances/get-latest-recovery-time)
- [gcloud sql operations list](https://docs.cloud.google.com/sdk/gcloud/reference/sql/operations/list)
- [gcloud sql operations describe](https://docs.cloud.google.com/sdk/gcloud/reference/sql/operations/describe)
- [Manage your data using Cloud SQL Studio (PostgreSQL)](https://cloud.google.com/sql/docs/postgres/manage-data-using-studio)
- [Terraform `google_sql_database_instance` resource (clone/import details)](https://third-party-mirror.googlesource.com/terraform-provider-google/+/refs/tags/v5.26.0/website/docs/r/sql_database_instance.html.markdown)
- [Terraform `google_sql_database` resource (import format)](https://third-party-mirror.googlesource.com/terraform-provider-google/+/refs/tags/v5.26.0/website/docs/r/sql_database.html.markdown)
- [Terraform `google_sql_user` resource (import format)](https://third-party-mirror.googlesource.com/terraform-provider-google-beta/+/refs/tags/v5.9.0/website/docs/r/sql_user.html.markdown)
