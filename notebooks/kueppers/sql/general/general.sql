-- ===================================================================
-- SQL Referenz-Skript: General - Grundlagen des Abfragens
-- ===================================================================
-- Dieses Skript zeigt grundlegende SQL-Abfragen als Referenz.
-- Voraussetzung: Die Tabelle 'Mitarbeiter' wurde mit dem
-- Setup-Skript erstellt und gefüllt.
-- ===================================================================


-- -------------------------------------------------
-- 1. SELECT und FROM: Daten auswählen
-- -------------------------------------------------

-- Wählt ALLE Spalten (*) und alle Zeilen aus der Tabelle 'Mitarbeiter' aus.
SELECT *
FROM Mitarbeiter;

-- Wählt nur die Spalten 'Vorname', 'Nachname' und 'Gehalt' aus.
SELECT Vorname, Nachname, Gehalt
FROM Mitarbeiter;


-- -------------------------------------------------
-- 2. AS: Spalten in der Ausgabe umbenennen (Alias)
-- -------------------------------------------------

-- Wählt Spalten aus und gibt ihnen im Ergebnis neue Namen. Nützlich für Berichte.
SELECT
    Nachname AS Familienname,
    Eintrittsdatum AS Startdatum
FROM Mitarbeiter;


-- -------------------------------------------------
-- 3. WHERE: Zeilen filtern
-- -------------------------------------------------

-- Findet alle Mitarbeiter, die in der Abteilung 'IT' sind.
SELECT *
FROM Mitarbeiter
WHERE Abteilung = 'IT';

-- Findet alle Mitarbeiter, die mehr als 70000 verdienen.
SELECT Vorname, Nachname, Gehalt
FROM Mitarbeiter
WHERE Gehalt > 70000;


-- -------------------------------------------------
-- 4. AND / OR: Filter kombinieren
-- -------------------------------------------------

-- Findet alle Mitarbeiter, die in der 'IT' sind UND mehr als 75000 verdienen (beide Bedingungen müssen wahr sein).
SELECT *
FROM Mitarbeiter
WHERE Abteilung = 'IT' AND Gehalt > 75000;

-- Findet alle Mitarbeiter, die entweder in der 'HR' sind ODER deren Nachname 'Schmitz' ist (eine der Bedingungen muss wahr sein).
SELECT *
FROM Mitarbeiter
WHERE Abteilung = 'HR' OR Nachname = 'Schmitz';


-- -------------------------------------------------
-- 5. Weitere WHERE-Operatoren
-- -------------------------------------------------

-- LIKE: Findet Muster. Hier: alle, deren Vorname mit 'L' beginnt (das '%' ist ein Platzhalter).
SELECT *
FROM Mitarbeiter
WHERE Vorname LIKE 'L%';

-- IN: Prüft, ob ein Wert in einer Liste von Werten enthalten ist. Sauberer als mehrere OR.
SELECT *
FROM Mitarbeiter
WHERE Abteilung IN ('Sales', 'HR');

-- BETWEEN: Prüft, ob ein Wert innerhalb eines Bereichs liegt (beide Grenzen inklusive).
SELECT Vorname, Gehalt
FROM Mitarbeiter
WHERE Gehalt BETWEEN 50000 AND 70000;

-- IS NULL: Prüft auf leere (NULL) Werte. Wichtig: `Abteilung = NULL` funktioniert nicht!
SELECT *
FROM Mitarbeiter
WHERE Abteilung IS NULL;


-- -------------------------------------------------
-- 6. ORDER BY: Ergebnisse sortieren
-- -------------------------------------------------

-- Sortiert alle Mitarbeiter nach ihrem Gehalt, absteigend (DESC = descending).
-- Für aufsteigend: ASC (ascending), was auch der Standard ist, wenn man nichts angibt.
SELECT Vorname, Nachname, Gehalt
FROM Mitarbeiter
ORDER BY Gehalt DESC;


-- -------------------------------------------------
-- 7. LIMIT: Anzahl der Ergebnisse begrenzen
-- -------------------------------------------------

-- Gibt nur die ersten 3 Zeilen der Tabelle zurück.
SELECT *
FROM Mitarbeiter
LIMIT 3;

-- Nützliche Kombination: Finde die 3 Mitarbeiter mit dem höchsten Gehalt.
-- Zuerst nach Gehalt absteigend sortieren, DANN die ersten 3 nehmen.
SELECT Vorname, Nachname, Gehalt
FROM Mitarbeiter
ORDER BY Gehalt DESC
LIMIT 3;