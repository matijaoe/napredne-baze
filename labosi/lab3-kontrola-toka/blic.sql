/*
Napisati funkciju koja za zadani JMBG nastavnika prikazuje broj ocijenjenih ispita po svakoj ocjeni formatu
"oc1  -  oc2  -  oc3  -  oc4  -oc  5".
Za svaku ocjenu je potrebno prikazati broj ocjena bez obzira je li bilo neke ocjene.

Ukoliko zadani JMBG nastavnika ne postoji u tablici NASTAVNICI, funkcija vraća poruku: "Nepostojeći JMBG nastavnika".
*/
DELIMITER ##
DROP FUNCTION IF EXISTS brojIspitaPoNastavniku;
CREATE FUNCTION brojIspitaPoNastavniku(zadaniJmbg char(13)) RETURNS VARCHAR(100)
    DETERMINISTIC
BEGIN
    DECLARE oc1, oc2, oc3, oc4, oc5 int DEFAULT 0;

    IF zadaniJmbg IN (SELECT jmbg
                      FROM nastavnici) THEN
        SELECT SUM(IF(o.ocjena = 1, 1, 0)),
               SUM(IF(o.ocjena = 2, 1, 0)),
               SUM(IF(o.ocjena = 3, 1, 0)),
               SUM(IF(o.ocjena = 4, 1, 0)),
               SUM(IF(o.ocjena = 5, 1, 0))
        INTO oc1, oc2, oc3, oc4, oc5
        FROM ocjene o
                 JOIN kolegiji k ON o.idKolegij = k.id
                 JOIN izvrsitelji i ON k.id = i.idKolegij
        WHERE i.jmbgNastavnik = zadaniJmbg;

        RETURN CONCAT_WS(' - ', oc1, oc2, oc3, oc4, oc5);
    ELSE
        RETURN 'Nepostojeći JMBG nastavnika';
    END IF;
END ##
DELIMITER ;

SELECT brojIspitaPoNastavniku('0110959390037') AS 'Prof Marks 1 2 3 4 5';
SELECT brojIspitaPoNastavniku('0110959390099') AS 'Prof Marks 1 2 3 4 5';


DELIMITER //
DROP FUNCTION IF EXISTS dohvatiOcjenePrekoNastavnika;
CREATE FUNCTION dohvatiOcjenePrekoNastavnika(p_jmbgNastavnika VARCHAR(15)) RETURNS VARCHAR(255) DETERMINISTIC
BEGIN
    DECLARE oc1, oc2, oc3, oc4, oc5 INT DEFAULT 0;
    CASE WHEN p_jmbgNastavnika IN (SELECT jmbg FROM nastavnici) THEN
        SELECT SUM(CASE WHEN ocjena = 1 THEN 1 ELSE 0 END),
               SUM(CASE WHEN ocjena = 2 THEN 1 ELSE 0 END),
               SUM(CASE WHEN ocjena = 3 THEN 1 ELSE 0 END),
               SUM(CASE WHEN ocjena = 4 THEN 1 ELSE 0 END),
               SUM(CASE WHEN ocjena = 5 THEN 1 ELSE 0 END)
        INTO oc1, oc2,oc3,oc4,oc5
        FROM ocjene
                 JOIN kolegiji k ON ocjene.idKolegij = k.id
                 JOIN izvrsitelji i ON k.id = i.idKolegij
        WHERE i.jmbgNastavnik = p_jmbgNastavnika;
        RETURN CONCAT_WS(' - ', oc1, oc2, oc3, oc4, oc5);
        ELSE
            RETURN 'Nepostojeći JMBG nastavnika';
        END CASE;
END //
DELIMITER ;

SELECT dohvatiOcjenePrekoNastavnika('0704987340304') AS ocjene;
