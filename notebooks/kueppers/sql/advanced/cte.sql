-- -----------------------------------------------------------------
-- 2. Common Table Expressions (CTEs)
-- -----------------------------------------------------------------
-- CTEs sind wie temporäre, benannte Ergebnismengen, die mit der
-- WITH-Klausel definiert werden. Sie machen komplexe Abfragen
-- DEUTLICH lesbarer und strukturierter als Subqueries.

-- Das gleiche Beispiel wie bei der Subquery in der FROM-Klausel, nur mit CTE.
-- Man kann die Logik Schritt für Schritt lesen.
WITH UmsatzProKunde AS (
    -- 1. Definiere die temporäre Tabelle 'UmsatzProKunde'
    SELECT
        KundenID,
        SUM(Menge * PreisProStueck) AS Gesamtumsatz
    FROM Bestellungen
    GROUP BY KundenID
)
-- 2. Verwende die eben definierte CTE in der finalen Abfrage
SELECT
    K.Name,
    U.Gesamtumsatz
FROM Kunden AS K
INNER JOIN UmsatzProKunde AS U ON K.KundenID = U.KundenID
WHERE U.Gesamtumsatz > 1000;


-- Beispiel mit MEHREREN CTEs, die aufeinander aufbauen.
-- Finde alle Kunden, deren Umsatz über dem Durchschnittsumsatz aller Kunden liegt.
WITH
UmsatzProKunde AS (
    -- CTE 1: Berechne den Umsatz für jeden Kunden
    SELECT
        KundenID,
        SUM(Menge * PreisProStueck) AS Gesamtumsatz
    FROM Bestellungen
    GROUP BY KundenID
),
DurchschnittsUmsatz AS (
    -- CTE 2: Berechne den Durchschnitt aus dem Ergebnis von CTE 1
    SELECT AVG(Gesamtumsatz) AS AvgUmsatz FROM UmsatzProKunde
)
-- Finale Abfrage: Verknüpfe die Ergebnisse und filtere
SELECT
    K.Name,
    U.Gesamtumsatz
FROM Kunden AS K
JOIN UmsatzProKunde AS U ON K.KundenID = U.KundenID
-- Das `CROSS JOIN` ist hier ein einfacher Weg, den einen Wert aus der zweiten CTE für jede Zeile verfügbar zu machen.
CROSS JOIN DurchschnittsUmsatz
WHERE U.Gesamtumsatz > DurchschnittsUmsatz.AvgUmsatz;