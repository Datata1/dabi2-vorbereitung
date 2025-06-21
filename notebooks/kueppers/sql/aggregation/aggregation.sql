-- ===================================================================
-- SQL Referenz-Skript: Aggregation - Daten gruppieren und zusammenfassen
-- ===================================================================
-- Dieses Skript zeigt, wie man Daten mit Aggregatfunktionen
-- zusammenfasst und nach Kategorien gruppiert.
-- ===================================================================


-- -----------------------------------------------------------------
-- 1. Aggregatfunktionen (ohne GROUP BY)
-- -----------------------------------------------------------------
-- Aggregatfunktionen fassen Informationen aus mehreren Zeilen zu
-- einem einzigen Wert zusammen. Angewendet auf die gesamte Tabelle.

-- COUNT(*): Zählt die Gesamtzahl aller Zeilen in der Tabelle.
SELECT COUNT(*) AS GesamtanzahlMitarbeiter
FROM Mitarbeiter;

-- COUNT(Spaltenname): Zählt alle Zeilen, in denen die Spalte NICHT NULL ist.
-- Das Ergebnis ist hier anders als bei COUNT(*), da eine Abteilung NULL ist.
SELECT COUNT(Abteilung) AS AnzahlMitarbeiterMitAbteilung
FROM Mitarbeiter;

-- SUM(): Berechnet die Summe aller Werte in einer numerischen Spalte.
SELECT SUM(Gehalt) AS GesamteGehaltskosten
FROM Mitarbeiter;

-- AVG(): Berechnet den Durchschnittswert.
SELECT AVG(Gehalt) AS Durchschnittsgehalt
FROM Mitarbeiter;

-- MIN() und MAX(): Finden den minimalen und maximalen Wert.
SELECT
    MIN(Gehalt) AS MinimalesGehalt,
    MAX(Gehalt) AS MaximalesGehalt
FROM Mitarbeiter;

-- Man kann auch mehrere Aggregatfunktionen in einer einzigen Abfrage kombinieren.
SELECT
    COUNT(*) AS Anzahl,
    AVG(Gehalt) AS Durchschnitt,
    MAX(Gehalt) AS Maximum
FROM Mitarbeiter;


-- -----------------------------------------------------------------
-- 2. GROUP BY: Daten gruppieren
-- -----------------------------------------------------------------
-- GROUP BY ist eine der mächtigsten Klauseln in SQL. Sie fasst
-- Zeilen mit gleichen Werten in einer Spalte zu einer Gruppe zusammen,
-- sodass Aggregatfunktionen auf jede Gruppe einzeln angewendet
-- werden können.

-- Zählt die Anzahl der Mitarbeiter PRO Abteilung.
SELECT
    Abteilung,
    COUNT(*) AS AnzahlProAbteilung
FROM Mitarbeiter
GROUP BY Abteilung;

-- Berechnet das Durchschnittsgehalt PRO Abteilung.
SELECT
    Abteilung,
    AVG(Gehalt) AS DurchschnittsgehaltProAbteilung
FROM Mitarbeiter
GROUP BY Abteilung
ORDER BY DurchschnittsgehaltProAbteilung DESC; -- Man kann die gruppierten Ergebnisse auch sortieren.


-- -----------------------------------------------------------------
-- 3. HAVING: Gruppen nach der Aggregation filtern
-- -----------------------------------------------------------------
-- WICHTIGER UNTERSCHIED:
-- WHERE filtert einzelne Zeilen, BEVOR sie gruppiert werden.
-- HAVING filtert ganze Gruppen, NACHDEM sie aggregiert wurden.

-- Finde nur die Abteilungen, die MEHR ALS 2 Mitarbeiter haben.
-- Ein `WHERE COUNT(*) > 2` würde nicht funktionieren!
SELECT
    Abteilung,
    COUNT(*) AS Anzahl
FROM Mitarbeiter
GROUP BY Abteilung
HAVING COUNT(*) > 2;

-- Ein komplexeres Beispiel, das alles kombiniert:
-- Finde Abteilungen, deren Durchschnittsgehalt für Mitarbeiter,
-- die nach 2020 eingestellt wurden, über 75000 liegt.
SELECT
    Abteilung,
    AVG(Gehalt) AS Durchschnittsgehalt
FROM Mitarbeiter
WHERE Eintrittsdatum > '2020-12-31' -- 1. Filtert die relevanten Mitarbeiter VOR der Gruppierung.
GROUP BY Abteilung                  -- 2. Gruppiert die verbleibenden Mitarbeiter.
HAVING AVG(Gehalt) > 75000;         -- 3. Filtert die Gruppen basierend auf dem Ergebnis der Aggregation.