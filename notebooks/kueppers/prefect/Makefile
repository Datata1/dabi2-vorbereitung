.PHONY: setup up down start 

.DEFAULT_GOAL := start

setup: 
	@echo ">>> Prüfe Host-Abhängigkeiten (uv)..."
	@if ! which uv > /dev/null; then \
		echo ">>> uv nicht gefunden, installiere uv via pip (Host)..."; \
		python -m pip install uv; \
	else \
		echo ">>> uv ist bereits auf dem Host installiert."; \
	fi

	@echo ">>> Prüfe dbt-Pakete im lokalen Projektverzeichnis..."; 
	@if [ ! -d "./dbt_setup/dbt_packages/dbt_utils" ]; then \
		echo ">>> dbt_packages lokal nicht gefunden, führe 'dbt deps' auf Host aus (benötigt uv)..."; \
		uv run dbt deps --project-dir ./dbt_setup/; \
	else \
		echo ">>> dbt_packages lokal bereits vorhanden, überspringe 'dbt deps'."; \
	fi
	@echo ">>> Host-Setup abgeschlossen."

up: 
	@echo ">>> Starte Docker Services..."
	sudo docker compose up --build --force-recreate

start: setup up 

down: 
	@echo ">>> Stoppe Docker Services..."
	sudo docker compose down
	sudo docker compose down --volumes 
	sudo rm -rf .venv

sudo:
	@echo ">>> Veränder Zugriffsrechte für volumes..."
	sudo chown $(id -u):$(id -g) ./dbt_setup/dev.duckdb
	sudo chown $(id -u):$(id -g) ./.venv

dbt-docs:
	@echo ">>> Generiere dbt-Dokumentation..."
	sudo chown -R $(id -u):$(id -g) dbt_setup
	cd packages/prefect && uv run dbt docs generate --project-dir ./dbt_setup/
	cd packages/prefect && uv run dbt docs serve --project-dir ./dbt_setup/ --port 8002