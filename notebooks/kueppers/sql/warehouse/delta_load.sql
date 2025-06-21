### 2. Delta Load (SCD Typ 1)

Nach dem initialen Full Load müssen wir nur noch die Änderungen aus dem Quellsystem übernehmen. Dieses Skript zeigt, wie man neue Datensätze einfügt und bestehende aktualisiert, ohne die Historie zu speichern (SCD Typ 1). Wir verwenden hierfür die `dim_store` als Beispiel.


-- =================================================================================
-- 02_delta_load.sql
-- =================================================================================
-- Zweck: Dieses Skript führt einen Delta Load für eine Dimension durch.
--        Änderungen werden überschrieben (SCD Typ 1) und neue Datensätze
--        werden hinzugefügt.
-- Annahme: Die Tabellen wurden bereits mit 01_create_star_schema.sql erstellt.
-- =================================================================================

-- ---------------------------------------------------------------------------------
-- SZENARIO: Der Name eines Stores hat sich geändert und ein neuer Store wurde hinzugefügt.
--           Wir simulieren das mit temporären Tabellen.
-- ---------------------------------------------------------------------------------

-- Angenommen, so sehen die NEUEN Daten im Quellsystem aus:
CREATE OR REPLACE VIEW source_store_updates AS
SELECT 1 AS `Store Number`, 'SuperStore Center' AS `Store Name` -- Namensänderung
UNION ALL
SELECT 2 AS `Store Number`, 'MegaMart' AS `Store Name` -- Unverändert
UNION ALL
SELECT 3 AS `Store Number`, 'Discount Corner' AS `Store Name`; -- Neuer Store


-- ---------------------------------------------------------------------------------
-- SCHRITT 1: GEÄNDERTE DATENSÄTZE AKTUALISIEREN (UPDATE)
-- ---------------------------------------------------------------------------------
-- Wir vergleichen die Quelltabelle mit unserer DWH-Dimensionstabelle, um
-- geänderte Attribute zu finden und diese zu überschreiben.

UPDATE dwh.dim_store dwh
JOIN source_store_updates src ON dwh.store_id = src.`Store Number`
SET
    dwh.store_name = src.`Store Name` -- Wir aktualisieren den Namen
-- FÜGE HIER WEITERE `SET`-ANWEISUNGEN FÜR ANDERE SPALTEN HINZU
WHERE
    dwh.store_name != src.`Store Name`; -- Führe das Update nur aus, wenn sich wirklich etwas geändert hat!


-- ---------------------------------------------------------------------------------
-- SCHRITT 2: NEUE DATENSÄTZE EINFÜGEN (INSERT)
-- ---------------------------------------------------------------------------------
-- Wir finden alle Datensätze, die im Quellsystem existieren, aber noch nicht
-- in unserer DWH-Dimensionstabelle. Ein LEFT JOIN ist dafür perfekt.

INSERT INTO dwh.dim_store (store_id, store_name, address, zip_code, city, county)
SELECT
    src.`Store Number`,
    src.`Store Name`,
    -- In einem echten Szenario würden hier die restlichen Attribute aus der Quelle kommen
    'Neue Adresse' AS address,
    '00000' AS zip_code,
    'Neue Stadt' AS city,
    'Neuer Kreis' AS county
FROM source_store_updates src
LEFT JOIN dwh.dim_store dwh ON src.`Store Number` = dwh.store_id
WHERE
    dwh.store_id IS NULL; -- Der Trick: Wenn die DWH-Seite NULL ist, existiert der Datensatz dort noch nicht.

-- =================================================================================
-- DELTA LOAD ABGESCHLOSSEN
-- =================================================================================

