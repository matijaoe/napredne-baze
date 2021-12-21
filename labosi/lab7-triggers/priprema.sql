/* 1. U bazi autoradionica: Postaviti okidač koji će prilikom unosa novog zapisa
u tablicu NALOG provjeriti ima li radnik na kojeg se nalog odnosi, za taj dan već
više od 8 sati po drugim nalozima. Ako ima, potrebno je datum novog naloga
povećati za 1 dan. */

DELIMITER //
DROP TRIGGER IF EXISTS provjeriSatiRadnika //
CREATE TRIGGER provjeriSatiRadnika
    BEFORE INSERT
    ON nalog
    FOR EACH ROW
BEGIN
    DECLARE br_sati int DEFAULT 0;
    SELECT SUM(OstvareniSatiRada) INTO br_sati FROM nalog WHERE nalog.sifRadnik = new.sifRadnik;
    IF br_sati > 8 THEN
        SET new.datPrimitkaNalog = new.datPrimitkaNalog + INTERVAL 1 DAY;
    END IF;
END;
//
DELIMITER ;


INSERT INTO nalog
VALUES (1173, 26, 456, '2006-04-28', 2, 3);

SELECT *
FROM nalog
WHERE sifRadnik = 456;


/* 3. U bazi autoradionica: Postaviti okidač koji će prilikom unosa novog zapisa
u tablicu NALOG dodijeliti klijentu onog radnika koji je već za njega popravljao
taj kvar (jednom ili više puta) i ostvario pri tome najveći broj sati rada (ako
je više radnika s istim uvjetom, dodijeliti bilo kojem od tih radnika).
Ako nema takvog, zapis ostaje nepromijenjen. */
DELIMITER //
DROP TRIGGER IF EXISTS odaberiRadnika //
CREATE TRIGGER odaberiRadnika
    BEFORE INSERT
    ON nalog
    FOR EACH ROW
BEGIN
    DECLARE naj_radnik int DEFAULT NULL;
    SELECT sifRadnik
    INTO naj_radnik
    FROM nalog
    WHERE sifKlijent = new.sifKlijent
      AND sifKvar = new.sifKvar
    GROUP BY sifRadnik
    ORDER BY SUM(OstvareniSatiRada) DESC
    LIMIT 1;

    IF naj_radnik IS NOT NULL THEN
        SET new.sifRadnik = naj_radnik;
    END IF;
END;
//
DELIMITER ;

-- 1127
SELECT *
FROM nalog;

INSERT INTO nalog
VALUES (1127, 1, 166, '2018-11-22', 2, 5);

SELECT sifRadnik, SUM(OstvareniSatiRada)
FROM nalog
WHERE sifKlijent = 1127
  AND sifKvar = 1
GROUP BY sifRadnik
ORDER BY SUM(OstvareniSatiRada) DESC;


/* 4. U bazi autoradionica: Postaviti okidač koji će prilikom promjene zapisa u
tablici radnik, dodatno obaviti promjenu osnovice plaće radnicima na temelju
broja ostvarenih sati rada prema grupama:
- Povećava za 300 ako radnik ima više od 100 sati
- Povećava za 100 ako radnik ima broj sati u opsegu [51 -100] sati
- Ostaje ista ako radnik ima broj sati u opsegu [0-50] sati */
DELIMITER //
DROP TRIGGER IF EXISTS promjeniOsnovicu //
CREATE TRIGGER promjeniOsnovicu
    BEFORE UPDATE
    ON radnik
    FOR EACH ROW
BEGIN
    DECLARE za_uvecat int DEFAULT 0;

    SELECT x.osnova
    INTO za_uvecat
    FROM (SELECT sifRadnik,
                 CASE
                     WHEN SUM(OstvareniSatiRada) > 100 THEN 300
                     WHEN SUM(OstvareniSatiRada) > 50 THEN 100
                     ELSE 0 END AS osnova
          FROM nalog n
          GROUP BY sifRadnik) x
    WHERE old.sifRadnik = x.sifRadnik;

    SET new.IznosOsnovice = old.IznosOsnovice + za_uvecat;

END;
//
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS promjeniOsnovicu2 //
CREATE TRIGGER promjeniOsnovicu2
    BEFORE UPDATE
    ON radnik
    FOR EACH ROW
BEGIN
    DECLARE za_uvecat int DEFAULT 0;

    SELECT x.osnova
    INTO za_uvecat
    FROM (SELECT CASE
                     WHEN SUM(OstvareniSatiRada) > 100 THEN 300
                     WHEN SUM(OstvareniSatiRada) > 50 THEN 100
                     ELSE 0 END AS osnova
          FROM nalog n
          WHERE old.sifRadnik = n.sifRadnik) x;

    SET new.IznosOsnovice = old.IznosOsnovice + za_uvecat;

END;
//
DELIMITER ;

SELECT r.*, suma_sati
FROM (SELECT n.sifRadnik, SUM(OstvareniSatiRada) suma_sati
      FROM radnik
               JOIN nalog n ON radnik.sifRadnik = n.sifRadnik
      GROUP BY n.sifRadnik) agr
         NATURAL JOIN radnik r
WHERE r.sifRadnik = 142;

UPDATE radnik
SET prezimeRadnik = 'HODL & STACK SATS'
WHERE sifRadnik = 142;


/* 5. U bazi studenti: Postaviti okidač koji će prilikom unosa negativne ocjene
provjeriti za studenta kolegij i broj polaganja. Ako student za dotični kolegij
već ima evidentirane tri negativne ocjene (ili više od tri), potrebno ju je
upisati u novu tablicu KOMISIJE novi zapis: idkolegija, jmbag studenta i datum
komisije (datum nove negativne ocjene + 1 mjesec). */
CREATE TABLE komisija
(
    idKolegija    INT,
    jmbg          CHAR(10),
    datumKomisije DATE
);

DELIMITER //
DROP TRIGGER IF EXISTS hendlajOcjenu //
CREATE TRIGGER hendlajOcjenu
    BEFORE INSERT
    ON ocjene
    FOR EACH ROW
BEGIN
    DECLARE v_br_neg int DEFAULT 0;

    SELECT br_neg
    INTO v_br_neg
    FROM (SELECT jmbagStudent, idKolegij, COUNT(*) br_neg
          FROM ocjene o
          WHERE ocjena = 1
          GROUP BY jmbagStudent, idKolegij
         ) agr
    WHERE jmbagStudent = new.jmbagStudent
      AND idKolegij = new.idKolegij;

    IF new.ocjena = 1 AND v_br_neg >= 3 THEN
        INSERT INTO komisija
        VALUES (new.idKolegij, new.jmbagStudent, DATE_ADD(new.datumPolaganja, INTERVAL 1 MONTH));
    END IF;


END;
//
DELIMITER ;


SELECT br_neg
FROM (SELECT jmbagStudent, idKolegij, COUNT(*) br_neg
      FROM ocjene o
      WHERE ocjena = 1
      GROUP BY jmbagStudent, idKolegij
     ) agr
WHERE jmbagStudent = '0036499965'
  AND idKolegij = 29;

SELECT *
FROM ocjene
WHERE jmbagStudent = '0036499965';

SELECT *
FROM komisija;

TRUNCATE TABLE komisija;

INSERT INTO ocjene
VALUES (29, '0036499965', '2018-01-20', '10:48:31', 1);