/* 1. U bazi autoradionica: Postaviti okidač koji će nakon unosa
naloga ažurirati tri nova atributa za ODJEL koji
izvršava taj nalog (broj odrađenih naloga, sumu ostvarenih sati
rada i prosječan broj ostvarenih sati rada.
Atribute dodati u tablicu ODJEL: brNaloga, sumaSati i avgSati */
SELECT *
FROM odjel;

ALTER TABLE odjel
    ADD (brNaloga INT,
         sumaSati INT,
         avgSati DECIMAL(6, 2));

DELIMITER //
DROP TRIGGER IF EXISTS azurirajOdjel //
CREATE TRIGGER azurirajOdjel
    BEFORE INSERT
    ON nalog
    FOR EACH ROW
BEGIN
    DECLARE v_sif_odjel, v_broj_naloga, v_suma_sati int DEFAULT NULL;
    DECLARE v_avg_sati decimal(6, 2) DEFAULT NULL;


    SELECT DISTINCT sifOdjel
    INTO v_sif_odjel
    FROM radnik
    WHERE sifRadnik = NEW.sifRadnik;

    SELECT COUNT(*)               br_nal,
           SUM(OstvareniSatiRada) sum_sati,
           AVG(OstvareniSatiRada) avg_sati
    INTO v_broj_naloga, v_suma_sati,v_avg_sati
    FROM nalog n
             NATURAL JOIN radnik r
    WHERE r.sifOdjel = v_sif_odjel;

    UPDATE odjel o
    SET brNaloga = v_broj_naloga,
        sumaSati = v_suma_sati,
        avgSati  = v_avg_sati
    WHERE o.sifOdjel = v_sif_odjel;

END;
//
DELIMITER ;

SELECT *
FROM nalog;

SELECT *
FROM odjel;

INSERT INTO nalog
VALUES (1174, 26, 330, '2018-11-29', 2, 3);


/* 2. U bazi autoradionica: Postaviti okidač koji će prilikom unosa novog
radnika u tablicu RADNIK, novom radniku dodijeliti šifru onog odjela koji
ima najmanje radnika (ukoliko je takvih odjela više, uzima bilo koji odjel s
minimalnim brojem radnika).
Osigurati da primarni ključ 'sifRadnik' bude jedinstven
(ne smije biti već dodijeljen nekom radniku), u suprotnom slučaju postaviti
taj ključ na sljedeću najveću vrijednost.
Napisati instrukciju koja će aktivirati okidač. */
DELIMITER //
DROP TRIGGER IF EXISTS dodajRadnika //
CREATE TRIGGER dodajRadnika
    BEFORE INSERT
    ON radnik
    FOR EACH ROW
BEGIN
    DECLARE v_odjel INT DEFAULT NULL;

    SELECT sifOdjel
    INTO v_odjel
    FROM (SELECT sifOdjel, COUNT(*) br_radnika
          FROM radnik
          GROUP BY sifOdjel
          ORDER BY br_radnika
          LIMIT 1) x;

    IF new.sifRadnik IN (SELECT sifRadnik FROM radnik) THEN
        SET new.sifRadnik = (SELECT MAX(sifRadnik) + 1 FROM radnik);
    END IF;

    SET new.sifOdjel = v_odjel;
END;
//
DELIMITER ;


SELECT sifOdjel
FROM (SELECT sifOdjel, COUNT(*) br_radnika
      FROM radnik
      GROUP BY sifOdjel
      ORDER BY br_radnika
      LIMIT 1) x;

SELECT *
FROM radnik
ORDER BY sifRadnik DESC
LIMIT 10;

INSERT INTO radnik
VALUES (599, 'josko', 'jokic', 10000, 1, 2.45, 2300);


/* 3. U bazi autoradionica: Postaviti okidač koji će nakon unosa novog
naloga ažurirati dva nova atributa za radnika kojemu pripada taj nalog
(sumu odrađenih sati i kategoriju klijenta).
Radnik dobiva kategorije prema sljedećem algoritmu (ovisi o broju naloga):
• 'D' broj naloga manji od 3,
• 'C' broj naloga između 3 i 10,
• 'B' broj naloga između 11 i 15,
• 'A' broj naloga veći od 15.
Atribute dodati u tablici RADNIK: sumaSati, katKlij.
Napisati instrukciju koja će aktivirati okidač.
*/

ALTER TABLE radnik
    ADD (sumaSati int, katKlij char(1));

DELIMITER //
DROP TRIGGER IF EXISTS unosNaloga //
CREATE TRIGGER unosNaloga
    BEFORE INSERT
    ON nalog
    FOR EACH ROW
BEGIN
    DECLARE v_suma_sati int DEFAULT 0;
    DECLARE v_oznaka char(1) DEFAULT NULL;

    SELECT suma_sati, oznaka
    INTO v_suma_sati, v_oznaka
    FROM (SELECT sifRadnik,
                 SUM(OstvareniSatiRada) suma_sati,
                 CASE
                     WHEN COUNT(*) > 15 THEN 'A'
                     WHEN COUNT(*) > 10 THEN 'B'
                     WHEN COUNT(*) > 2 THEN 'C'
                     ELSE 'D'
                     END AS             oznaka
          FROM nalog
          GROUP BY sifRadnik) x
    WHERE x.sifRadnik = new.sifRadnik;

    UPDATE radnik SET sumaSati = v_suma_sati, katKlij = v_oznaka WHERE sifRadnik = new.sifRadnik;
END;
//
DELIMITER ;


SELECT *
FROM nalog
WHERE sifRadnik = 256;

SELECT *
FROM radnik
WHERE sifRadnik = 256;

INSERT INTO nalog
VALUES (1369, 21, 256, '2020-08-06', 2, 6);


/* 4. U bazi STUDENTI: Postaviti okidač koji će u slučaju promjene
smjera studenta, njegovom prezimenu dodati tekst
' Uvjet: br_neg_ocj= ' i broj negativnih ocjena, samo ako je student
imao negativnih ocjena.
Osigurati također da se studentu ne može mijenjati njegov JMBAG.
Napisati instrukciju koja će aktivirati okidač.
*/
DELIMITER //
DROP TRIGGER IF EXISTS negativneStudenta //
CREATE TRIGGER negativneStudenta
    BEFORE UPDATE
    ON studenti
    FOR EACH ROW
BEGIN
    DECLARE v_neg int DEFAULT 0;

    SELECT COUNT(*)
    INTO v_neg
    FROM ocjene o
    WHERE o.jmbagStudent = old.jmbag
      AND ocjena = 1;

    IF (new.idSmjer <> old.idSmjer AND v_neg > 0) THEN
        SET new.prezime = CONCAT(old.prezime, ' Uvjet: br_neg_ocj= ', v_neg);
    END IF;

    IF NEW.jmbag <> OLD.jmbag THEN
        SET NEW.jmbag = OLD.jmbag;
    END IF;
END;
//
DELIMITER ;

SELECT *
FROM studenti s
WHERE s.jmbag = '0036499965';

UPDATE studenti
SET idSmjer = 4,
    jmbag= '9999999999'
WHERE jmbag = '0036499965';