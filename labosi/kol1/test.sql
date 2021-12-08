/*
Napisati proceduru koja će za zadanu godinu prikazati podatke po kvarovima.
Izuzeti kvarove koji su imali samo 1 nalog i broj radnika manji od 2.
Prikazati sljedeće podatke: šifru i naziv kvara, broj radnika za kvar, broj ostvarenih naloga
te oznaku  "Više od 5 radnika"  ili "Manje od 5 radnika".

Sort po broju radnika padajući.  Zadatak riješiti pomoću kursora i privremene tablice.
Napisati primjer poziva procedure.
 */

DELIMITER ##
DROP PROCEDURE IF EXISTS podaciOKvarovima;
CREATE PROCEDURE podaciOKvarovima(zadanaGodina INT)
BEGIN
    DECLARE c_sifra, c_br_radnika, c_br_naloga INT DEFAULT NULL;
    DECLARE c_naziv, c_oznaka varchar(255) DEFAULT NULL;
    DECLARE kraj BOOLEAN DEFAULT FALSE;
    DECLARE kur CURSOR FOR (
        SELECT k.sifKvar,
               k.nazivKvar,
               k.brojRadnika,
               agr.brNaloga,
               IF(brojRadnika > 5, 'Više od 5 radnika', 'Manje od 5 radnika') oznaka
        FROM (SELECT sifKvar, COUNT(*) brNaloga
              FROM nalog
              WHERE YEAR(datPrimitkaNalog) = zadanaGodina
              GROUP BY sifKvar
              HAVING brNaloga <> 1
             ) agr
                 JOIN kvar k ON k.sifKvar = agr.sifKvar
        WHERE brojRadnika >= 2
        ORDER BY brojRadnika DESC
    );
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj = TRUE;

    DROP TEMPORARY TABLE IF EXISTS temp_table;
    CREATE TEMPORARY TABLE temp_table
    (
        sifra       INT,
        naziv       VARCHAR(255),
        brojRadnika INT,
        Br_naloga   INT,
        oznaka      VARCHAR(255)
    );

    OPEN kur;

    petlja:
    LOOP
        FETCH kur INTO c_sifra,c_naziv,c_br_radnika, c_br_naloga, c_oznaka;

        IF kraj = TRUE THEN
            LEAVE petlja;
        END IF;

        INSERT INTO temp_table
        VALUES (c_sifra, c_naziv, c_br_radnika, c_br_naloga, c_oznaka);
    END LOOP;

    SELECT * FROM temp_table;
    CLOSE kur;

END ##
DELIMITER ;

CALL podaciOKvarovima(2019);


/* Napisati proceduru koja za zadani OIB ustanove prikazuje u vidu MATRICE id i nazive kolegija te
    koliko je svaki kolegij dobio ocjena, za svaku ocjenu (1-5) pojedinačno.
    Prikazati i prosječnu ocjenu smjera kao i standardnu devijaciju.
    Ukoliko zadani OIB ne postoji u tablici USTANOVE, procedura vraća poruku: "Nepostojeći OIB ustanove.".
    Napisati smisleni primjer poziva ovog pohranjenog zadatka.
*/
DELIMITER ##
DROP PROCEDURE IF EXISTS matricaZaKolegij;
CREATE PROCEDURE matricaZaKolegij(zadaniOib CHAR(11))
BEGIN
    IF zadaniOib IN (SELECT oib FROM ustanove) THEN
        SELECT k.id,
               k.naziv,
               SUM(IF(o.ocjena = 1, 1, 0)) AS OC_1,
               SUM(IF(o.ocjena = 2, 1, 0)) AS OC_2,
               SUM(IF(o.ocjena = 3, 1, 0)) AS OC_3,
               SUM(IF(o.ocjena = 4, 1, 0)) AS OC_4,
               SUM(IF(o.ocjena = 5, 1, 0)) AS OC_5,
               ROUND(AVG(o.ocjena), 2)     AS AVG_Kolegija,
               ROUND(STD(o.ocjena), 2)     AS STD_Kolegija
        FROM ocjene o
                 JOIN kolegiji k ON o.idKolegij = k.id
                 JOIN smjerovi s ON k.idSmjer = s.id
        WHERE s.oibUstanova = zadaniOib
        GROUP BY k.id, k.naziv
        ORDER BY AVG_Kolegija DESC;
    ELSE
        SELECT 'Nepostojeći OIB ustanove.' AS Poruka;
    END IF;
END ##
DELIMITER ;

CALL matricaZaKolegij('08814003451');
CALL matricaZaKolegij('02024882310');
CALL matricaZaKolegij('12212121212');


