DELIMITER //
DROP TRIGGER IF EXISTS koef2 //
CREATE TRIGGER koef2
    BEFORE UPDATE
    ON radnik
    FOR EACH ROW
BEGIN
    IF new.KoefPlaca > 2 THEN
        SET new.KoefPlaca = old.KoefPlaca + 2;
    END IF;
END;
//
DELIMITER ;

SELECT *
FROM radnik
WHERE sifRadnik = 126;


UPDATE radnik
SET KoefPlaca = KoefPlaca + 3
WHERE sifRadnik = 126;


/*
U bazi studenti u tablicu nastavnici dodati novu kolonu
'lozinkaTimestamp'.
Potrebno je osigurati da se nakon svake promjene lozinke nekom od
nastavnika, automatski upiše vremenska oznaka promjene lozinke u
kolonu 'lozinkaTimestamp’ (za tog nastavnika).
*/
ALTER TABLE nastavnici
    ADD COLUMN lozinkaTimestamp TIMESTAMP;

SELECT *
FROM nastavnici;

DELIMITER //
DROP TRIGGER IF EXISTS lozinka_trigger //
CREATE TRIGGER lozinka_trigger
    BEFORE UPDATE
    ON nastavnici
    FOR EACH ROW
BEGIN
    IF new.lozinka = old.lozinka THEN
        SET new.lozinkaTimestamp = NOW();
    END IF;
END;
//
DELIMITER ;

SELECT *
FROM nastavnici;

UPDATE nastavnici
SET lozinka = 'matija'
WHERE jmbg = '0404964361006';


/* 1. U bazi autoradionica: Postaviti okidač koji će nakon unosa
naloga ažurirati tri nova atributa za ODJEL koji
izvršava taj nalog (broj odrađenih naloga, sumu ostvarenih sati
rada i prosječan broj ostvarenih sati rada.
Atribute dodati u tablicu ODJEL: brNaloga, sumaSati i avgSati.
Napisati instrukciju koja će aktivirati okidač.
*/

ALTER TABLE odjel
    ADD COLUMN brNaloga INT,
    ADD COLUMN sumaSati INT,
    ADD COLUMN avgSati  decimal(6, 2);

SELECT *
FROM odjel;


SELECT *
FROM kvar;

DELIMITER //
DROP TRIGGER IF EXISTS unos_naloga //
CREATE TRIGGER unos_naloga
    BEFORE INSERT
    ON nalog
    FOR EACH ROW
BEGIN
    DECLARE v_sifOdjel int;
    DECLARE v_brNaloga INT;
    DECLARE v_sumaSati INT;
    DECLARE v_avgSati decimal(6, 2);

    SELECT DISTINCT sifOdjel
    INTO v_sifOdjel
    FROM radnik
    WHERE sifRadnik = NEW.sifRadnik;

    SELECT COUNT(*), SUM(OstvareniSatiRada), AVG(OstvareniSatiRada)
    INTO v_brNaloga, v_sumaSati, v_avgSati
    FROM nalog
             JOIN radnik r ON nalog.sifRadnik = r.sifRadnik
    WHERE r.sifOdjel = v_sifOdjel;

    UPDATE odjel
    SET brNaloga = v_brNaloga,
        sumaSati = v_sumaSati,
        avgSati  = v_avgSati
    WHERE sifOdjel = v_sifOdjel;
END;
//
DELIMITER ;

INSERT INTO nalog (sifKlijent, sifKvar, sifRadnik, datPrimitkaNalog, prioritetNalog, OstvareniSatiRada)
VALUES (1, 1, 1, '2019-01-01', '1', 1);

SELECT *
FROM nalog
WHERE datPrimitkaNalog = '2019-01-01';


# novi zad
ALTER TABLE klijent
    ADD COLUMN brojNaloga int,
    ADD COLUMN kategorija CHAR(1);

SELECT *
FROM klijent;

DELIMITER //
DROP TRIGGER IF EXISTS unos_novog_naloga //
CREATE TRIGGER unos_novog_naloga
    BEFORE INSERT
    ON nalog
    FOR EACH ROW
BEGIN
    DECLARE v_ukProsjekSati decimal(6, 2);
    DECLARE v_brojNaloga INT;
    DECLARE v_kategorija CHAR(1);

    SELECT ROUND(AVG(OstvareniSatiRada), 2) INTO v_ukProsjekSati FROM nalog;

    SELECT COUNT(*),
           CASE
               WHEN COUNT(*) > 16 AND AVG(OstvareniSatiRada) >= v_ukProsjekSati THEN 'X'
               WHEN COUNT(*) > 16 AND AVG(OstvareniSatiRada) < v_ukProsjekSati THEN 'A'
               WHEN COUNT(*) > 12 THEN 'B'
               WHEN COUNT(*) > 4 THEN 'C'
               ELSE 'D' END
    INTO v_brojNaloga, v_kategorija
    FROM nalog
    WHERE sifKlijent = NEW.sifKlijent;

    IF v_kategorija IN ('A', 'X') THEN
        UPDATE klijent SET prezimeKlijent = UPPER(prezimeKlijent);
    END IF;

    UPDATE klijent
    SET brojNaloga = v_brojNaloga,
        kategorija = v_kategorija
    WHERE sifKlijent = NEW.sifKlijent;
END;
//
DELIMITER ;


/* 4. U bazi STUDENTI: Postaviti okidač koji će u slučaju promjene
smjera studenta, njegovom prezimenu dodati tekst
' Uvjet: br_neg_ocj= ' i broj negativnih ocjena, samo ako je student
imao negativnih ocjena.
Osigurati također da se studentu ne može mijenjati njegov JMBAG.
Napisati instrukciju koja će aktivirati okidač.
*/
DELIMITER //
DROP TRIGGER IF EXISTS uvjetni_upis //
CREATE TRIGGER uvjetni_upis
    BEFORE UPDATE
    ON studenti.studenti
    FOR EACH ROW
BEGIN
    DECLARE v_brojNeg int DEFAULT 0;

    IF new.jmbag <> old.jmbag THEN
        SET new.jmbag = old.jmbag;
    END IF;

    SELECT COUNT(*)
    INTO v_brojNeg
    FROM ocjene
    WHERE ocjena = 1
      AND jmbagStudent = old.jmbag;

    IF new.idSmjer <> old.idSmjer AND v_brojNeg > 0 THEN
        SET new.prezime = CONCAT(old.prezime, ' br_neg_ocj=', v_brojNeg);
    END IF;
END;
//
DELIMITER ;

SELECT *
FROM studenti
WHERE jmbag = '0036499965';

SELECT *
FROM ocjene
WHERE jmbagStudent = '0036499965';

UPDATE studenti
SET idSmjer = 2,
    jmbag= '9999999999'
WHERE jmbag = '0036499965';


/* 2. U bazi autoradionica: Postaviti okidač koji će prilikom unosa novog
radnika u tablicu RADNIK, novom radniku dodijeliti šifru onog odjela koji
ima najmanje radnika (ukoliko je takvih odjela više, uzima bilo koji odjel s
minimalnim brojem radnika).
Osigurati da primarni ključ 'sifRadnik' bude jedinstven
(ne smije biti već dodijeljen nekom radniku), u suprotnom slučaju postaviti
taj ključ na sljedeću najveću vrijednost.
Napisati instrukciju koja će aktivirati okidač. */
DELIMITER //
DROP TRIGGER IF EXISTS dodajRadnik //
CREATE TRIGGER dodajRadnik
    BEFORE INSERT
    ON radnik
    FOR EACH ROW
BEGIN
    DECLARE v_sifOdjel int DEFAULT NULL;

    SELECT sifOdjel
    INTO v_sifOdjel
    FROM radnik
    GROUP BY sifOdjel
    ORDER BY COUNT(sifRadnik)
    LIMIT 1;

    IF new.sifRadnik IN (SELECT DISTINCT sifRadnik FROM radnik) THEN
        SET new.sifRadnik = (SELECT MAX(sifRadnik) + 1 FROM radnik);
    END IF;

    SET new.sifOdjel = v_sifOdjel;
END;
//
DELIMITER ;


SELECT *
FROM radnik;


/*U bazi STUDENTI: Postaviti okidač koji će prilikom izmjene ID
kolegija (tbl KOLEGIJI) osigurati sljedeću konzistentnost podataka:

Provjeriti: dolazi li do promjene ID kolegija uopće, ako ne,
trigger miruje (kraj), ako da, izvršava sljedeće aktivnosti
ID kolegija mora biti novi, ne smije postojati u tablici;
ukoliko nije stavlja se sljedeći slobodni (max+1)
naziv kolegija dobiva iza naziva tekst 'UPDATED'
sve ocjene trebaju biti zamijenjene novom šifrom kolegija.
Napisati instrukciju koja će aktivirati okidač.

*/
DELIMITER //
DROP TRIGGER IF EXISTS izmjena_kolegija //
CREATE TRIGGER izmjena_kolegija
    BEFORE UPDATE
    ON kolegiji
    FOR EACH ROW
BEGIN
    IF new.id <> old.id THEN
        SET new.id = (SELECT MAX(id) + 1 FROM kolegiji);
        SET new.naziv = CONCAT(old.naziv, '_UPDATED');

        -- UPDATE ocjene SET idKolegij = new.id WHERE idKolegij = old.id;
    END IF;
END;
//
DELIMITER ;

SELECT *
FROM kolegiji;

-- Cannot delete or update a parent row: a foreign key constraint fails (`studenti`.`izvrsitelji`, CONSTRAINT `fk_izvrsitelji_kolegiji1`
-- FOREIGN KEY (`idKolegij`) REFERENCES `kolegiji` (`id`))
UPDATE kolegiji
SET id = 100
WHERE id = 1;

SELECT *
FROM kolegiji
WHERE id = 1;

SELECT *
FROM ocjene;


