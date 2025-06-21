-- ===================================================================
-- SQL Referenz-Skript: Joins - Daten aus mehreren Tabellen kombinieren
-- ===================================================================
-- Dieses Skript zeigt, wie man Tabellen mit verschiedenen JOIN-Typen
-- verknüpft. Es verwendet die Tabellen 'Kunden' und 'Bestellungen'.
-- ===================================================================


-- -----------------------------------------------------------------
-- 1. INNER JOIN
-- -----------------------------------------------------------------
-- Gibt NUR die Zeilen zurück, für die es in BEIDEN Tabellen einen
-- passenden Eintrag gibt (basierend auf der ON-Bedingung).
-- Ergebnis: Kunde 'Tom Klein' (ohne Bestellung) und die Bestellung
-- mit der ungültigen KundenID 5 werden NICHT angezeigt.

SELECT
    K.Name,
    K.Stadt,
    B.Produkt,
    B.Menge
FROM Kunden AS K
INNER JOIN Bestellungen AS B
    ON K.KundenID = B.KundenID;


-- -----------------------------------------------------------------
-- 2. LEFT JOIN
-- -----------------------------------------------------------------
-- Gibt ALLE Zeilen aus der LINKEN Tabelle (Kunden) zurück und die
-- passenden Zeilen aus der RECHTEN Tabelle (Bestellungen).
-- Wenn es rechts keinen Treffer gibt, werden die Spalten mit NULL gefüllt.
-- Ergebnis: 'Tom Klein' wird angezeigt, aber seine Bestell-Spalten sind NULL.

SELECT
    K.Name,
    K.Stadt,
    B.Produkt,
    B.Menge
FROM Kunden AS K
LEFT JOIN Bestellungen AS B
    ON K.KundenID = B.KundenID;


-- Nützliches Muster mit LEFT JOIN: Finde alle Kunden, die noch NIE bestellt haben.
SELECT K.Name
FROM Kunden AS K
LEFT JOIN Bestellungen AS B
    ON K.KundenID = B.KundenID
WHERE B.BestellungsID IS NULL; -- Der Trick: Filtere auf die Zeilen, bei denen der Join keine Übereinstimmung fand.


-- -----------------------------------------------------------------
-- 3. RIGHT JOIN
-- -----------------------------------------------------------------
-- Gibt ALLE Zeilen aus der RECHTEN Tabelle (Bestellungen) zurück.
-- Das Gegenteil von LEFT JOIN.
-- Ergebnis: Die Bestellung für den unbekannten Kunden (ID 5) wird angezeigt.
-- In der Praxis wird meistens LEFT JOIN bevorzugt, ist aber funktional identisch.

SELECT
    K.Name,
    B.Produkt,
    B.Menge
FROM Kunden AS K
RIGHT JOIN Bestellungen AS B
    ON K.KundenID = B.KundenID;


-- -----------------------------------------------------------------
-- 4. FULL OUTER JOIN
-- -----------------------------------------------------------------
-- Gibt ALLE Zeilen aus BEIDEN Tabellen zurück. Es werden sowohl
-- Kunden ohne Bestellung als auch Bestellungen ohne Kunden angezeigt.
-- Kombiniert quasi das Ergebnis von LEFT und RIGHT JOIN.
-- (Hinweis: MySQL unterstützt FULL OUTER JOIN nicht direkt,
-- man simuliert es mit UNION. PostgreSQL, SQL Server etc. können es.)

SELECT
    K.Name,
    B.Produkt
FROM Kunden AS K
FULL OUTER JOIN Bestellungen AS B
    ON K.KundenID = B.KundenID;


-- -----------------------------------------------------------------
-- 5. UNION vs. UNION ALL
-- -----------------------------------------------------------------
-- UNION kombiniert die Zeilen-Ergebnisse von zwei separaten SELECT-Abfragen.
-- Es ist KEIN JOIN, da es nicht spaltenweise verknüpft.
-- UNION entfernt Duplikate, UNION ALL lässt Duplikate drin (und ist schneller).

-- Erstellt eine kombinierte Liste aller Kundennamen und potenzieller Neukunden.
SELECT Name FROM Kunden
UNION
SELECT Name FROM Kunden WHERE Stadt = 'Berlin'; -- 'Anna Schmidt' und 'Tom Klein' sind Duplikate und werden nur einmal angezeigt.

SELECT Name FROM Kunden
UNION ALL
SELECT Name FROM Kunden WHERE Stadt = 'Berlin'; -- Hier werden 'Anna Schmidt' und 'Tom Klein' doppelt angezeigt.