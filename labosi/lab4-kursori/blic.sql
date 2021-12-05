/*
Napisati funkciju koja će ažurirati tablicu ODJEL na način da će u dva novostvorena atributa 'brRadnika' i 'brNaloga'
upisati potrebne vrijednosti. Atribut 'brRadnika' sadrži broj radnika koji PRIPADAJU tom odjelu bez obzira da li su
imali naloge, dok atribut 'brNaloga' sadrži broj naloga koji su  OSTVARILI radnici koji pripadaju tom odjelu.
(Dodavanje atributa napisati van funkcije  ALTER TABLE table_name ADD column_name datatype ).

Funkcija mora vratiti broj odjela koje je dohvatila i ažurirala. Zadatak riješiti pomoću kursora.
Napisati primjer poziva funkcije.

Slika s porukom prikazuje primjer rezultata po završetku funkcije a druga slika prikazuje promjene u bazi.
*/
ALTER TABLE odjel
    ADD brRadnika INT;
ALTER TABLE odjel
    ADD brNaloga INT;
DELIMITER ##
DROP FUNCTION IF EXISTS dopuniNaloge;
CREATE FUNCTION dopuniNaloge() RETURNS VARCHAR(50)
    DETERMINISTIC
BEGIN
    DECLARE dohvaceno, azurirano int DEFAULT 0;
    DECLARE c_naziv_odj varchar(100) DEFAULT NULL;
    DECLARE c_sif_odj, c_br_radnika, c_br_radn_s_nalogom INT DEFAULT 0;
    DECLARE kraj BOOLEAN DEFAULT FALSE;
    DECLARE kur CURSOR FOR (
        SELECT o.sifOdjel,
               o.nazivOdjel,
               agr.br_radnika,
               COUNT(*) br_radnika_s_nalogom
        FROM nalog n
                 JOIN radnik r ON n.sifRadnik = r.sifRadnik
                 JOIN odjel o ON r.sifOdjel = o.sifOdjel
                 JOIN (SELECT sifOdjel, COUNT(*) br_radnika
                       FROM radnik
                       GROUP BY sifOdjel) agr ON agr.sifOdjel = o.sifOdjel
        GROUP BY o.sifOdjel, o.nazivOdjel
    );
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj = TRUE;


    OPEN kur;
    SELECT FOUND_ROWS() INTO dohvaceno;

    petlja:
    LOOP
        FETCH kur INTO c_sif_odj, c_naziv_odj, c_br_radnika, c_br_radn_s_nalogom;

        IF kraj = TRUE THEN
            LEAVE petlja;
        END IF;

        UPDATE odjel SET brRadnika = c_br_radnika, brNaloga = IFNULL(c_br_radn_s_nalogom, 0) WHERE sifOdjel = c_sif_odj;

        SET azurirano = azurirano + 1;

    END LOOP;

    CLOSE kur;

    RETURN CONCAT('Dohvaceno: ', dohvaceno, ' | Azurirano: ', azurirano);

END ##
DELIMITER ;

SELECT dopuniNaloge();