/*
U bazi autoradionica: Postaviti okidač koji će prilikom unosa novog radnika u tablicu RADNIK, novom radniku
dodijeliti koeficijent i osnovicu na temelju prosjeka odjela kojem će pripasti.

Osigurati da primarni ključ 'sifRadnik' bude jedinstven (ne smije biti već dodijeljen nekon radniku),
u suprotnom slučaju postaviti taj ključ na sljedeću najveću vrijednost.

Napisati instrukciju koja će aktivirati okidač.
*/

DELIMITER //
DROP TRIGGER IF EXISTS unosRadnika //
CREATE TRIGGER unosRadnika
    BEFORE INSERT
    ON radnik
    FOR EACH ROW
BEGIN
    DECLARE v_avg_koef DECIMAL(3, 2) DEFAULT NULL;
    DECLARE v_avg_osn DECIMAL(6, 2) DEFAULT NULL;

    SELECT avg_koef, avg_osn
    INTO v_avg_koef, v_avg_osn
    FROM (SELECT o.sifOdjel, AVG(KoefPlaca) avg_koef, AVG(IznosOsnovice) avg_osn
          FROM odjel o
                   JOIN radnik r ON o.sifOdjel = r.sifOdjel
          GROUP BY o.sifOdjel) agr
    WHERE agr.sifOdjel = new.sifOdjel;


    IF new.sifRadnik IN (SELECT sifRadnik FROM radnik) THEN
        SET new.sifRadnik = (SELECT MAX(sifRadnik) + 1 FROM radnik);
    END IF;

    SET new.KoefPlaca = v_avg_koef,
        new.IznosOsnovice = v_avg_osn;
END;
//
DELIMITER ;


INSERT INTO radnik
VALUES (166, 'Matija', 'Osrečki', 10000, 13, 3.2, 3000);


-- TESTS
SELECT *
FROM radnik;

SELECT avg_koef, avg_osn
FROM (SELECT o.sifOdjel, AVG(KoefPlaca) avg_koef, AVG(IznosOsnovice) avg_osn
      FROM odjel o
               JOIN radnik r ON o.sifOdjel = r.sifOdjel
      GROUP BY o.sifOdjel) agr
WHERE sifOdjel = 1;

SELECT *
FROM radnik
ORDER BY sifRadnik DESC
LIMIT 10;

INSERT INTO radnik
VALUES (330, 'Marian', 'Babić', 10000, 1, 5.4, 7000);
