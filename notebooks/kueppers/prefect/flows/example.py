from datetime import datetime
from prefect import flow, task, get_run_logger
from pathlib import Path
import time

from tasks.dbt_runner import run_dbt_command_runner

# --- Konfiguration ---
DUCKDB_PATH = "/app/dbt_setup/dev.duckdb"
STAGING_TABLE_PREFIX = "stg_raw_"

APP_DIR = Path("/app")
DBT_PROJECT_DIR = APP_DIR / "dbt_setup"
DBT_PROFILES_DIR = DBT_PROJECT_DIR


# --- Der Haupt-Flow ---
@flow(name="CDC MinIO to DWH (Synchronous)", log_prints=True) 
def dwh_flow():
    logger = get_run_logger()
    final_message = "Flow initialisiert."

    debug_status = run_dbt_command_runner( 
        dbt_args=["debug"],
        project_dir=DBT_PROJECT_DIR,
        profiles_dir=DBT_PROFILES_DIR
    )
    if not debug_status:
        logger.error("DBT debug fehlgeschlagen. Breche Flow ab.")
        return "DBT debug fehlgeschlagen."
    logger.info("DBT debug erfolgreich.")

    return final_message

if __name__ == "__main__":
    pass