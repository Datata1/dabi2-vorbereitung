import asyncio
import asyncpg
import sys
import os
import requests
from pathlib import Path
import traceback
import logging

from prefect import get_client
from prefect.server.schemas.actions import WorkPoolCreate
from prefect.exceptions import ObjectNotFound
from prefect.workers.process import ProcessWorker

from flows.example import dwh_flow as target_flow

DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "oltp")
DB_USER = os.getenv("DB_USER", "datata1")
DB_PASSWORD = os.getenv("DB_PASSWORD", "devpassword")


logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# --- Konfiguration --- 
WORK_POOL_NAME = "dabi2"
APP_BASE_PATH = Path("/app/")

# --- Konfiguration für DWH Flow ---
DWH_DEPLOYMENT_NAME = "dwh-pipeline"
DWH_FLOW_SCRIPT_PATH = Path("./flows/example.py") 
DWH_FLOW_FUNCTION_NAME = target_flow.__name__ 
DWH_FLOW_ENTRYPOINT = f"./flows/example.py:{DWH_FLOW_FUNCTION_NAME}" 
DWH_TAGS = ["dwh", "bucket", "autoscheduled"]
DWH_DESCRIPTION = "DWH Pipeline"
INTERVAL_SECONDS = 60


async def create_or_get_work_pool(client, name: str):
    logger.info(f"Prüfe Work Pool '{name}'...")
    try:
        pool = await client.read_work_pool(work_pool_name=name)
        logger.info(f"Work Pool '{name}' existiert bereits.")
        return pool
    except ObjectNotFound:
        logger.info(f"Work Pool '{name}' nicht gefunden. Erstelle...")
        try:
            pool_config = WorkPoolCreate(name=name, type="process", concurrency_limit=1)
            pool = await client.create_work_pool(work_pool=pool_config)
            logger.info(f"Work Pool '{name}' erstellt.")
            return pool
        except Exception as e:
            logger.error(f"FEHLER: Konnte Work Pool '{name}' nicht erstellen: {e}", file=sys.stderr)
            if hasattr(e, 'response') and e.response:
                try:
                    error_detail = await e.response.json()
                    logger.error(f"Server Response: {error_detail}", file=sys.stderr)
                except:
                     logger.error(f"Server Response (raw): {await e.response.text()}", file=sys.stderr)
            sys.exit(1)

async def main():
    """Hauptfunktion zum Einrichten und Starten des Prefect Workers via API."""
    async with get_client() as client:
        await create_or_get_work_pool(client, WORK_POOL_NAME)

        logger.info(f"\n--- Deploying DWH Flow: {DWH_DEPLOYMENT_NAME} ---")
        try:
            logger.info(f"Ermittle Flow ID für Funktion: {DWH_FLOW_FUNCTION_NAME}")
            dwh_flow_id = await client.create_flow_from_name(DWH_FLOW_FUNCTION_NAME)
            logger.info(f"Flow ID für DWH: {dwh_flow_id}")

            logger.info(f"Sende POST request für DWH Deployment...")
            dwh_deployment_response = requests.post(
                f"http://prefect:4200/api/deployments", 
                json={
                    "name": DWH_DEPLOYMENT_NAME,
                    "flow_id": str(dwh_flow_id),
                    "work_pool_name": WORK_POOL_NAME,
                    "entrypoint": DWH_FLOW_ENTRYPOINT,
                    "enforce_parameter_schema": False,
                    "path": str(APP_BASE_PATH),
                    "tags": DWH_TAGS,
                    "description": DWH_DESCRIPTION,
                },
                headers={"Content-Type": "application/json"},
                timeout=30 
            )
            dwh_deployment_response.raise_for_status() 
            dwh_deployment_data = dwh_deployment_response.json()
            dwh_deployment_id = dwh_deployment_data.get('id')
            if dwh_deployment_id:
                 logger.info(f"DWH Deployment '{DWH_DEPLOYMENT_NAME}' (ID: {dwh_deployment_id}) erfolgreich erstellt/aktualisiert.")
            else:
                 logger.warning(f"DWH Deployment erstellt, aber keine ID in Antwort gefunden: {dwh_deployment_data}")
        except requests.exceptions.RequestException as e:
            logger.error(f"FEHLER bei OLTP Deployment HTTP-Anfrage: {e}", file=sys.stderr)
            if hasattr(e, 'response') and e.response is not None: logger.info(f"Response Body: {e.response.text}", file=sys.stderr)
        except Exception as e:
            logger.error(f"FEHLER beim Erstellen/Verarbeiten des OLTP Deployments: {e}", file=sys.stderr)
            traceback.logger.info_exc(file=sys.stderr)

    logger.info(f"Starte Worker für Pool '{WORK_POOL_NAME}'...")
    try:
        worker = ProcessWorker(work_pool_name=WORK_POOL_NAME)
        await worker.start() 

    except KeyboardInterrupt:
        logger.info("\nWorker gestoppt.")
        sys.exit(0)
    except Exception as e:
        logger.info(f"Ein unerwarteter Fehler ist beim Starten des Workers aufgetreten: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except Exception as e:
        logger.info(f"Ein kritischer Fehler ist aufgetreten: {e}", file=sys.stderr)
        sys.exit(1)