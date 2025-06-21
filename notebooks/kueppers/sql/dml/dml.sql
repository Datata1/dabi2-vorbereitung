-- ===================================================================
-- SQL Referenz-Skript: DML (Data Manipulation Language)
-- ===================================================================
-- Dieses Skript zeigt, wie man Datenzeilen einfügt (INSERT),
-- aktualisiert (UPDATE) und löscht (DELETE).
-- ===================================================================


-- -----------------------------------------------------------------
-- 1. INSERT INTO: Neue Zeilen hinzufügen
-- -----------------------------------------------------------------

-- Syntax 1 (bevorzugt): Spalten explizit angeben.
-- Das ist sicherer, falls sich die Reihenfolge der Spalten in der Tabelle ändert.
INSERT INTO Mitarbeiter (MitarbeiterID, Vorname, Nachname, Abteilung, Gehalt, Eintrittsdatum)
VALUES (105, 'Laura', 'Fischer', 'Sales', 68000.00, '2018-05-20');


-- Syntax 2: Ohne Angabe der Spaltennamen.
-- Erfordert, dass die Werte in exakt der richtigen Reihenfolge und Anzahl angegeben werden.
-- Fehleranfälliger, aber schneller zu schreiben.
INSERT INTO Mitarbeiter
VALUES (106, 'Peter', 'Hofmann', 'IT', 85000.00, '2017-09-01');


-- Syntax 3: Mehrere Zeilen auf einmal einfügen.
-- Das ist deutlich performanter als einzelne INSERT-Befehle.
INSERT INTO Mitarbeiter (MitarbeiterID, Vorname, Nachname, Abteilung)
VALUES
    (107, 'Sofia', 'Zimmermann', 'HR'),  -- Gehalt und Datum sind hier NULL
    (108, 'Max', 'Krüger', 'Sales');     -- Gehalt und Datum sind hier NULL


-- Überprüfe das Ergebnis aller INSERTS
SELECT * FROM Mitarbeiter;


-- -----------------------------------------------------------------
-- 2. UPDATE: Bestehende Zeilen verändern
-- -----------------------------------------------------------------
-- VORSICHT: Immer eine WHERE-Klausel verwenden, sonst werden
-- ALLE Zeilen in der Tabelle geändert!

-- Ändert das Gehalt für einen bestimmten Mitarbeiter.
UPDATE Mitarbeiter
SET Gehalt = 70000.00
WHERE MitarbeiterID = 105;


-- Ändert mehrere Spalten gleichzeitig für einen Mitarbeiter.
UPDATE Mitarbeiter
SET
    Abteilung = 'Management',
    Gehalt = 95000.00
WHERE MitarbeiterID = 106;


-- Ändert Werte für eine ganze Gruppe von Zeilen.
-- Gibt allen Mitarbeitern in der HR-Abteilung eine Gehaltserhöhung von 5%.
UPDATE Mitarbeiter
SET Gehalt = Gehalt * 1.05
WHERE Abteilung = 'HR';


-- Überprüfe das Ergebnis der UPDATES
SELECT * FROM Mitarbeiter ORDER BY MitarbeiterID;


-- -----------------------------------------------------------------
-- 3. DELETE: Zeilen löschen
-- -----------------------------------------------------------------
-- EXTREME VORSICHT: Ein DELETE-Befehl ohne WHERE-Klausel
-- löscht ALLE Daten in der Tabelle unwiderruflich!

-- Löscht einen bestimmten Mitarbeiter aus der Tabelle.
DELETE FROM Mitarbeiter
WHERE MitarbeiterID = 108;


-- Überprüfe das Ergebnis des DELETEs
SELECT * FROM Mitarbeiter ORDER BY MitarbeiterID;