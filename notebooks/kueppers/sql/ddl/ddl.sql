-- ===================================================================
-- SQL Referenz-Skript: DDL (Data Definition Language)
-- ===================================================================
-- Dieses Skript zeigt, wie man die Struktur von Datenbank-Tabellen
-- erstellt (CREATE), verändert (ALTER) und löscht (DROP).
-- ===================================================================


-- -----------------------------------------------------------------
-- 1. CREATE TABLE: Eine neue Tabelle erstellen
-- -----------------------------------------------------------------
-- Definiert eine neue Tabelle 'Produkte' mit verschiedenen Spalten,
-- Datentypen und Constraints (Einschränkungen).

-- Wir erstellen zuerst eine einfache 'Lieferanten'-Tabelle für die Foreign-Key-Beziehung.
CREATE TABLE Lieferanten (
    LieferantenID INT PRIMARY KEY,
    Firma VARCHAR(100) NOT NULL,
    Kontaktperson VARCHAR(100)
);


-- Jetzt die Haupttabelle 'Produkte'
CREATE TABLE Produkte (
    -- Spaltenname   Datentyp         Constraints
    ProduktID      INT              PRIMARY KEY, -- Eindeutiger Schlüssel für jedes Produkt
    Produktname    VARCHAR(100)     NOT NULL,    -- Text, muss angegeben werden
    SKU            VARCHAR(50)      UNIQUE,      -- Eindeutige Artikelnummer, darf nicht doppelt vorkommen
    Kategorie      VARCHAR(50),
    Preis          DECIMAL(10, 2)   NOT NULL,    -- Zahl mit 10 Stellen, davon 2 nach dem Komma
    Lagerbestand   INT              DEFAULT 0,   -- Standardwert ist 0, falls nicht anders angegeben
    Verfuegbar     BOOLEAN          DEFAULT TRUE,
    ErstelltAm     TIMESTAMP        DEFAULT CURRENT_TIMESTAMP, -- Zeitstempel des Erstellens
    LieferantenID  INT,

    -- Definition eines Foreign Keys, der auf die Tabelle 'Lieferanten' verweist
    FOREIGN KEY (LieferantenID) REFERENCES Lieferanten(LieferantenID)
);


-- -----------------------------------------------------------------
-- 2. ALTER TABLE: Eine bestehende Tabelle verändern
-- -----------------------------------------------------------------
-- Nützlich, wenn sich die Anforderungen ändern und die Struktur
-- einer Tabelle nachträglich angepasst werden muss.

-- ADD COLUMN: Fügt eine neue Spalte hinzu.
ALTER TABLE Produkte
ADD COLUMN Gewicht_kg DECIMAL(6, 2);

-- DROP COLUMN: Entfernt eine Spalte.
ALTER TABLE Produkte
DROP COLUMN Kategorie;

-- RENAME COLUMN: Benennt eine Spalte um.
-- (Syntax kann je nach SQL-Dialekt leicht variieren)
ALTER TABLE Produkte
RENAME COLUMN Produktname TO Artikelbezeichnung;

-- ALTER COLUMN / MODIFY COLUMN: Ändert den Datentyp einer Spalte.
-- (Syntax variiert stark, z.B. `ALTER COLUMN` in PostgreSQL/SQL Server, `MODIFY COLUMN` in MySQL)
-- Beispiel für PostgreSQL:
-- ALTER TABLE Produkte
-- ALTER COLUMN Artikelbezeichnung TYPE VARCHAR(150);


-- -----------------------------------------------------------------
-- 3. DROP TABLE: Eine Tabelle komplett löschen
-- -----------------------------------------------------------------
-- VORSICHT: Dieser Befehl löscht die Tabelle und ALLE darin
-- enthaltenen Daten unwiderruflich!

-- `IF EXISTS` verhindert einen Fehler, falls die Tabellen nicht (mehr) existieren.
DROP TABLE IF EXISTS Produkte;
DROP TABLE IF EXISTS Lieferanten;