/*
 U bazi studenti:
Napisati funkciju koja prima godinu, te za istu  računa ukupan broj upisanih studenata te godine, odnosno  vraća sljedeću poruku:
"U godini GODINA je upisano N studenata."
Napisati smisleni primjer poziva ovog pohranjenog zadatka.
 */

DELIMITER #
DROP FUNCTION IF EXISTS studentiPoGodini;
CREATE FUNCTION studentiPoGodini(trazenaGodina int) RETURNS varchar(50)
    DETERMINISTIC
BEGIN
    DECLARE broj_upisanih int DEFAULT 0;
    SELECT COUNT(*)
    INTO broj_upisanih
    FROM studenti.studenti
    WHERE YEAR(datumUpisa) = trazenaGodina;

    RETURN CONCAT_WS(' ', 'U godini', trazenaGodina, 'upisano je', broj_upisanih, 'studentata.');
END #
DELIMITER ;

SELECT studentiPoGodini(2019) AS broj_upisanih;


/*
Napisati proceduru koja će za zadanu godinu prikazati podatke po kolegijima.
Odabrati kolegije koji su imali više od 2 položena ispita.

Prikazati sljedeće podatke:  id i naziv kolegija, prosječnu ocjenu, standardnu devijaciju te broj položenih ispita.
Sort po standardnoj devijaciji silazno. Napisati smisleni primjer poziva ovog pohranjenog zadatka.
*/

DELIMITER #
DROP PROCEDURE IF EXISTS kolegijZaGodinu;
CREATE PROCEDURE kolegijZaGodinu(trazenaGodina int)
BEGIN
    SELECT k.naziv, agr.*
    FROM (SELECT idKolegij, AVG(ocjena) prosjek, STDDEV(ocjena) AS stddev, COUNT(*) broj_ispita
          FROM ocjene o
          WHERE YEAR(o.datumPolaganja) = trazenaGodina
          GROUP BY o.idKolegij) agr
             JOIN kolegiji k ON agr.idKolegij = k.id
    ORDER BY agr.stddev DESC;
END #
DELIMITER ;

call kolegijZaGodinu(2016);