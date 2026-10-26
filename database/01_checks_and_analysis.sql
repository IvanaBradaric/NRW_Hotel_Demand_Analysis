-- 1. 

CREATE Database NRW_Hotel_Demand;

USE NRW_Hotel_Demand;

SELECT COUNT(*) as row_count
FROM hotel_demand;

--2.
-- Anzahl der NULL-Werte prüfen und mit den Ergebnissen aus Python vergleichen

SELECT COUNT(*) AS missing_arrivals_yoy
FROM hotel_demand
WHERE arrivals_yoy_pct IS NULL;

SELECT COUNT(*) AS missing_overnight_stays
FROM hotel_demand
WHERE overnight_stays_yoy_pct IS NULL;

SELECT COUNT(*) AS missing_average_stay
FROM hotel_demand
WHERE average_stay IS NULL;


-- Eindeutige Kombinationen von Städtenamen und Stadtcodes anzeigen

SELECT DISTINCT city, city_code
FROM hotel_demand;

--3.

-- Gesamte Ankünfte und Übernachtungen pro Stadt und Jahr berechnen

SELECT city, 
		year, 
		SUM(arrivals) AS arrivals,
		SUM(overnight_stays) AS overnight_stays
FROM hotel_demand
WHERE origin_continent = 'Insgesamt'
GROUP BY city, year;

-- Korrigierte CSV-Datei mit den richtigen Daten für Aachen erneut importiert

SELECT COUNT(*) AS row_count
FROM hotel_demand_corrected

----------------------------------------------------------------------------------
-- Ankünfte und Übernachtungen nach Stadt und Jahr zusammenfassen und sortieren

SELECT city,
	   year,
	   SUM(arrivals) AS arrivals,
	   SUM(overnight_stays) AS overnight_stays
FROM hotel_demand_corrected
WHERE origin_continent = 'Insgesamt'
GROUP BY city, year
ORDER BY city, year;

--4.
--------------------------------------------------------------------------
-- Jährliche Übernachtungen je Stadt berechnen und den Vorjahreswert anzeigen

SELECT city, year, SUM(overnight_stays) AS total_stays,
LAG(SUM(overnight_stays) , 1)
OVER(PARTITION BY city  ORDER BY year) AS prev_year_stays
FROM hotel_demand_corrected
WHERE origin_continent = 'Insgesamt'
GROUP BY city, year;


-- Städte innerhalb jedes Jahres nach der prozentualen Veränderung der Übernachtungen absteigend sortieren

WITH yearly_stays AS (
	SELECT city, year, SUM(overnight_stays) AS total_stays,
	LAG(SUM(overnight_stays) , 1)
	OVER(PARTITION BY city  ORDER BY year) AS prev_year_stays
	FROM hotel_demand_corrected
	WHERE origin_continent = 'Insgesamt'
	GROUP BY city, year
)
SELECT city,
	   year,
	   total_stays,
	   prev_year_stays,
	   CAST(
			(total_stays - prev_year_stays)*100.0 / prev_year_stays AS decimal(10,2)) AS stays_yoy_pct
FROM yearly_stays
ORDER BY year, stays_yoy_pct DESC;


--5.
---------------------------------------------------------------------------------------
-- Monatliche Übernachtungen je Stadt und Jahr für 2022–2025 zur Analyse der Saisonalität zusammenfassen

SELECT city,
	   year,
	   month_number,
	   SUM(overnight_stays) AS total_stays
FROM hotel_demand_corrected
WHERE origin_continent = 'Insgesamt' AND year BETWEEN 2022 AND 2025
GROUP BY city,year, month_number
ORDER BY city,year, month_number;


USE NRW_Hotel_Demand
--6.
----------------------------------------------------------------------
-- Übernachtungen nach Herkunft der Gäste summieren
SELECT city, 
	   year,
	   origin_continent, 
	   SUM(overnight_stays) AS total_stays
FROM hotel_demand_corrected
WHERE origin_continent != 'Insgesamt'
GROUP BY city,year, origin_continent
ORDER BY year;

-- Gesamte Übernachtungen je Stadt und Jahr berechnen.
SELECT city, 
	   year, 
	   SUM(overnight_stays) AS total_stays
FROM hotel_demand_corrected
WHERE origin_continent = 'Insgesamt'
GROUP BY city, year;


-- Übernachtungen nach Gästeherkunft je Stadt und Jahr summieren, ohne die Kategorie Insgesamt.
WITH origin_stays AS (
	SELECT city, 
	   year,
	   origin_continent, 
	   SUM(overnight_stays) AS total_stays
	FROM hotel_demand_corrected
	WHERE origin_continent != 'Insgesamt'
	GROUP BY city,year, origin_continent
), city_year_totals AS(   -- Gesamte Übernachtungen je Stadt und Jahr anhand der Kategorie Insgesamt berechnen.
	SELECT city, 
	   year, 
	   SUM(overnight_stays) AS total_stays
	FROM hotel_demand_corrected
	WHERE origin_continent = 'Insgesamt'
	GROUP BY city, year
)
-- Stadt, Jahr, Gästeherkunft sowie Übernachtungen nach Herkunft und insgesamt anzeigen.
SELECT origin_stays.city, 
	   origin_stays.year, 
	   origin_stays.origin_continent,
	   origin_stays.total_stays AS origin_nights,
	   city_year_totals.total_stays AS city_total_nights,
	   -- Prozentualen Anteil an den gesamten Übernachtungen berechnen und auf zwei Dezimalstellen runden.
	   CAST(origin_stays.total_stays * 100.0 / city_year_totals.total_stays AS decimal(10,2)) AS origin_share_pct
FROM origin_stays
-- Beide Ergebnisse über dieselbe Stadt und dasselbe Jahr verknüpfen.
JOIN city_year_totals
	ON origin_stays.city = city_year_totals.city
	AND origin_stays.year = city_year_totals.year
-- Nach Stadt und Jahr, anschließend nach dem Anteil absteigend sortieren.
ORDER BY origin_stays.city, origin_stays.year, origin_share_pct DESC


--7.
-- Durchschnittliche Aufenthaltsdauer je Stadt und Jahr als gesamte Übernachtungen geteilt durch gesamte Ankünfte berechnen.


SELECT city, 
	   year, 
	   SUM(overnight_stays) AS total_stays,
	   SUM(arrivals) AS total_arrivals,
	   CAST(SUM(overnight_stays) * 1.0 / SUM(arrivals) AS decimal(10,2)) AS avg_stay
FROM hotel_demand_corrected
WHERE origin_continent = 'Insgesamt'
GROUP BY city, year
ORDER BY city, year