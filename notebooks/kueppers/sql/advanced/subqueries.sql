-- ===================================================================
-- SQL Referenz-Skript: Advanced - Subqueries & CTEs
-- ===================================================================
-- Dieses Skript zeigt, wie man komplexe Abfragen mit Unterabfragen
-- (Subqueries) und Common Table Expressions (CTEs) strukturiert.
-- ===================================================================


-- -----------------------------------------------------------------
-- 1. Subqueries (Unterabfragen)
-- -----------------------------------------------------------------
-- Eine Subquery ist eine SELECT-Abfrage, die in einer anderen
-- SQL-Anweisung verschachtelt ist.

-- 1a. Subquery in der WHERE-Klausel (häufigster Fall)

-- Finde alle Kunden, die schon einmal einen 'Laptop' bestellt haben.
-- Die innere Abfrage findet alle Kunden-IDs von Laptop-Bestellungen,
-- die äußere Abfrage filtert dann die Kundentabelle.
SELECT *
FROM Kunden
WHERE KundenID IN (
    SELECT KundenID FROM Bestellungen WHERE Produkt = 'Laptop'
);

-- Finde alle Bestellungen, deren Menge über der Durchschnittsmenge ALLER Bestellungen liegt.
-- Die innere Abfrage berechnet einen einzelnen Wert (Skalar), der dann außen verwendet wird.
SELECT *
FROM Bestellungen
WHERE Menge > (
    SELECT AVG(Menge) FROM Bestellungen
);


-- 1b. Subquery in der FROM-Klausel
-- Die Subquery wird hier wie eine temporäre Tabelle behandelt, die man auch mit einem Alias benennen muss.
-- Berechne den Gesamtumsatz pro Kunde und zeige dann nur die Kunden an, die mehr als 1000€ ausgegeben haben.
SELECT
    K.Name,
    UmsatzProKunde.Gesamtumsatz
FROM Kunden AS K
INNER JOIN (
    SELECT
        KundenID,
        SUM(Menge * PreisProStueck) AS Gesamtumsatz
    FROM Bestellungen
    GROUP BY KundenID
) AS UmsatzProKunde ON K.KundenID = UmsatzProKunde.KundenID
WHERE UmsatzProKunde.Gesamtumsatz > 1000;
