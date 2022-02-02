/*
 U bazi STUDENTI: Postaviti okidač koji će prilikom izmjene ID kolegija (tbl KOLEGIJI) osigurati sljedeću konzistentnost podataka: 

Provjeriti: dolazi li do promjene ID kolegija uopće, ako ne, trigger miruje (kraj), ako da, izvršava sljedeće aktivnosti
ID kolegija mora biti novi, ne smije postojati u tablici;  ukoliko nije stavlja se sljedeći slobodni (max+1)
sve ocjene iz starog kolegija trebaju biti zamijenjene novom šifrom kolegija.
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
        IF new.id IN (SELECT DISTINCT id FROM kolegiji) THEN
            SET new.id = (SELECT MAX(id) + 1 FROM kolegiji);
        END IF;

        UPDATE ocjene SET idKolegij = new.id WHERE idKolegij = old.id;
    END IF;
END;
//
DELIMITER ;

SELECT *
FROM kolegiji;


INSERT INTO kolegiji (id, naziv, opis, idSmjer)
VALUES (48, 'test kolegij', 'test opis', 1);

# aktivira okidač
UPDATE kolegiji
SET id = 155
WHERE id = 48;


/* U bazi autoradionica: Izraditi pogled uz korištenje CTE-a koji će po kvartalima i radnicima sadržavati podatke
   prema slici lijevo (sort po kvartalu i šifri radnika).
   Nakon toga koristeći kreirani Pogled, prikazati podatke prema slici desno (sort po šifri odjela).
*/

CREATE OR REPLACE VIEW odjel_kvartali AS
WITH agr AS (
    SELECT QUARTER(datPrimitkaNalog) kvart, n.sifRadnik, COUNT(*) br_naloga, SUM(OstvareniSatiRada) suma_sati
    FROM nalog n
    GROUP BY QUARTER(datPrimitkaNalog), n.sifRadnik
)
SELECT agr.*, r.imeRadnik, r.prezimeRadnik, r.sifOdjel
FROM radnik r
         NATURAL JOIN agr
ORDER BY 1, 2;

-- default pogled
SELECT *
FROM odjel_kvartali;

-- podaci koristeci pogled
SELECT o.sifOdjel, o.nazivOdjel, SUM(br_naloga) ukup_br_naloga, SUM(suma_sati) ukup_suma_sati
FROM odjel_kvartali
         NATURAL JOIN odjel o
GROUP BY o.sifOdjel, o.nazivOdjel
ORDER BY sifOdjel;