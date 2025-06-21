
### 3. Slowly Changing Dimensions (SCD Typ 2)

Dieses Skript zeigt die Implementierung von SCD Typ 2, bei der Änderungen historisiert werden. Dazu fügen wir der Dimensionstabelle einen künstlichen Primärschlüssel (`surrogate key`) und Gültigkeitsdaten (`valid_from`, `valid_to`) hinzu. Wir verwenden die `dim_product` als Beispiel.


-- =================================================================================
-- 03_scd_type_2.sql
-- =================================================================================
-- Zweck: Implementierung einer "Slowly Changing Dimension" vom Typ 2.
--        Änderungen an Attributen führen zu neuen, versionierten Einträgen
--        in der Dimension, anstatt alte Werte zu überschreiben.
--
-- Konzept: Wir verwenden einen künstlichen Primärschlüssel (Surrogate Key)
--          und Gültigkeitsdaten, um die Historie abzubilden.
-- =================================================================================

-- ---------------------------------------------------------------------------------
-- SCHRITT 0: ANPASSEN DER DIMENSIONSTABELLE FÜR SCD TYP 2
-- ---------------------------------------------------------------------------------
DROP TABLE IF EXISTS dwh.fact_sales; -- Muss wegen Foreign Key zuerst gelöscht werden
DROP TABLE IF EXISTS dwh.dim_product_scd2;

CREATE TABLE dwh.dim_product_scd2 (
    product_sk INT PRIMARY KEY AUTO_INCREMENT,  -- SURROGATE KEY: Künstlicher, eindeutiger Schlüssel
    product_id INT,                           -- BUSINESS KEY: Der Schlüssel aus dem Quellsystem
    product_name VARCHAR(255),
    category_name VARCHAR(100),
    valid_from DATE,                          -- Gültig ab diesem Datum
    valid_to DATE,                            -- Gültig bis zu diesem Datum
    is_current BOOLEAN                        -- Ein Flag, um den aktuell gültigen Datensatz schnell zu finden
);

-- Initialer Load der SCD2-Tabelle (ähnlich wie im Full Load)
INSERT INTO dwh.dim_product_scd2 (product_id, product_name, category_name, valid_from, valid_to, is_current)
SELECT
    p.`Product Number`,
    p.`Product Description`,
    c.`Category Name`,
    '1900-01-01' AS valid_from, -- Gültig seit Anbeginn der Zeit
    '9999-12-31' AS valid_to,   -- Gültig bis in alle Ewigkeit
    TRUE AS is_current
FROM source.product p
LEFT JOIN source.category c ON p.Category = c.Category;


-- ---------------------------------------------------------------------------------
-- SZENARIO: Der Name eines Produkts hat sich geändert.
-- ---------------------------------------------------------------------------------
SET @today = CURDATE();
SET @yesterday = SUBDATE(@today, 1);

-- Angenommen, so sehen die NEUEN Daten im Quellsystem aus:
CREATE OR REPLACE VIEW source_product_updates AS
SELECT 101 AS `Product Number`, 'Super-Laptop Pro X' AS `Product Description`; -- Namensänderung


-- ---------------------------------------------------------------------------------
-- SCHRITT 1: ALTE DATENSÄTZE "SCHLIESSEN" (EXPIRE)
-- ---------------------------------------------------------------------------------
-- Finde alle aktuell gültigen Datensätze im DWH, für die sich in der Quelle
-- ein Attribut geändert hat, und setze ihr `valid_to`-Datum auf gestern.

UPDATE dwh.dim_product_scd2 dwh
JOIN source_product_updates src ON dwh.product_id = src.`Product Number`
SET
    dwh.valid_to = @yesterday,
    dwh.is_current = FALSE
WHERE
    dwh.is_current = TRUE -- Stelle sicher, dass wir nur den aktuellsten Datensatz anpassen
    AND dwh.product_name != src.`Product Description`; -- Das ist die Änderungsprüfung!


-- ---------------------------------------------------------------------------------
-- SCHRITT 2: NEUE VERSIONEN DER GEÄNDERTEN DATENSÄTZE EINFÜGEN
-- ---------------------------------------------------------------------------------
-- Füge für die im vorigen Schritt geschlossenen Datensätze eine neue Zeile
-- mit den aktuellen Werten aus der Quelle ein. Diese neue Zeile ist ab heute gültig.

INSERT INTO dwh.dim_product_scd2 (product_id, product_name, valid_from, valid_to, is_current)
SELECT
    src.`Product Number`,
    src.`Product Description`,
    @today AS valid_from,       -- Gültig ab heute
    '9999-12-31' AS valid_to,   -- Offenes Ende
    TRUE AS is_current
FROM source_product_updates src
-- Stelle sicher, dass wir nur für geänderte Produkte einen neuen Eintrag anlegen
JOIN dwh.dim_product_scd2 dwh ON src.`Product Number` = dwh.product_id
WHERE
    dwh.valid_to = @yesterday -- Nur die, die wir gerade geschlossen haben
    AND dwh.product_name != src.`Product Description`;


-- ---------------------------------------------------------------------------------
-- ANMERKUNG: Schritte für komplett neue oder gelöschte Produkte müssten hier noch
-- ergänzt werden, analog zum Delta Load Skript (02_delta_load.sql).
-- =================================================================================
-- SCD TYP 2 PROZESS ABGESCHLOSSEN
-- =================================================================================