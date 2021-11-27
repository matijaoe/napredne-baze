/* 1. Napisati proceduru koja će za zadanu šifru klijenta vratiti: jmbg
klijenta, ime i prezime klijenta, godinu unosa klijenta u sustav,
broj naloga koji se na njega odnose i sumu ostvarenih sati rada po nalozima za
tog klijenta. Prikazati i sveukupan broj sati za sve klijente preko izlaznog
parametra.
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/

DELIMITER #
DROP PROCEDURE IF EXISTS vratiKlijenta;
CREATE PROCEDURE vratiKlijenta(IN sifra varchar(50), OUT total_sati int)
BEGIN
    SELECT jmbgKlijent,
           imeKlijent,
           prezimeKlijent,
           YEAR(datUnosKlijent) godina_unosa,
           nalog_agr.broj_naloga,
           nalog_agr.suma_sati
    FROM (SELECT sifKlijent, COUNT(*) broj_naloga, SUM(OstvareniSatiRada) suma_sati
          FROM nalog
          WHERE sifKlijent = sifra
          GROUP BY sifKlijent
         ) nalog_agr
             NATURAL JOIN klijent;

    SELECT SUM(OstvareniSatiRada) INTO total_sati FROM nalog;
END #
DELIMITER ;

CALL vratiKlijenta(1160, @ukupno_sati);
SELECT @ukupno_sati;


/* 2. Napisati proceduru koja će za zadanu šifru odjela i mjesec vratiti :
šifru radnika, ime i prezime radnika spojeno, broj_naloga, prosječne sate rada, koef plaće,
iznos osnovice te plaću na 2 decimale (plaća je umnožak osnovice i koef plaće).
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/

DELIMITER #
DROP PROCEDURE IF EXISTS vratiRadnikeOdjela;
CREATE PROCEDURE vratiRadnikeOdjela(sifra_odjela varchar(50), bez_mjeseca int)
BEGIN
    SELECT r.sifRadnik,
           CONCAT_WS(' ', r.imeRadnik, r.prezimeRadnik) AS ime_prezime_rad,
           COUNT(*)                                        broj_naloga,
           AVG(OstvareniSatiRada)                          prosj_sati_rada,
           KoefPlaca,
           IznosOsnovice,
           ROUND(IznosOsnovice * KoefPlaca, 2)          AS placa_radnika
    FROM nalog n
             JOIN radnik r ON n.sifRadnik = r.sifRadnik
    WHERE r.sifOdjel = sifra_odjela
      AND MONTH(datPrimitkaNalog) != bez_mjeseca
    GROUP BY r.sifRadnik;
END #
DELIMITER ;

CALL vratiRadnikeOdjela(2, 7);

/* 3. Napisati proceduru koja će za zadani raspon prosječnih ocjena (ocjena_od,
ocjena_do) prikazati po kolegijima sljedeće podatke:
naziv kolegija, id smjera kojem kolegij pripada, id kolegija, broj položenih ispita i
prosječnu ocjenu kolegija
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/

DELIMITER #
DROP PROCEDURE IF EXISTS kolegijiPoRasponuOcjena;
CREATE PROCEDURE kolegijiPoRasponuOcjena(ocjena_min double, ocjena_max double)
BEGIN
    SELECT k.naziv, k.idSmjer, agr.*
    FROM (SELECT idKolegij, COUNT(*) broj_ispita, AVG(ocjena) prosj_ocjena
          FROM ocjene
          WHERE ocjena BETWEEN ocjena_min AND ocjena_max
          GROUP BY idKolegij) agr
             JOIN kolegiji k ON k.id = agr.idKolegij
    ORDER BY agr.prosj_ocjena;
END #
DELIMITER ;


CALL kolegijiPoRasponuOcjena(2.2, 3.3);


/* 4. Napisati funkciju koja će za zadanu šifru kvara ispisati koliko je bilo naloga
po toj šifri kvara, prema sljedećem formatu. 'Broj naloga je: n.'
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/
DELIMITER #
DROP FUNCTION IF EXISTS naloziZaKvar;
CREATE FUNCTION naloziZaKvar(zadaniKvar int) RETURNS varchar(50)
    DETERMINISTIC
BEGIN
    DECLARE broj_naloga int DEFAULT 0;

    SELECT COUNT(*)
    INTO broj_naloga
    FROM nalog
    WHERE sifKvar = zadaniKvar;

    RETURN CONCAT('Broj naloga je: ', broj_naloga);

END #
DELIMITER ;

SELECT naloziZaKvar(2);


/* 5. Napisati funkciju koja će za zadanu ocjenu ispisati tu ocjenu, koliko je bilo
tih ocjena kao i zadnji datum kada je ta ocjena ostvarena, prema sljedećem formatu.
'Zadana ocjena= x Broj ocjena= y Max datum = yyyy-mm-dd' */

DELIMITER #
DROP FUNCTION IF EXISTS ocjenaStats;
CREATE FUNCTION ocjenaStats(zadanaOcjena int) RETURNS varchar(100)
    DETERMINISTIC
BEGIN
    DECLARE zadnji_datum varchar(50) DEFAULT NULL;
    DECLARE broj_ocjena int DEFAULT 0;

    SELECT DATE_FORMAT(MAX(datumPolaganja), '%Y-%m-%d'), COUNT(*)
    INTO zadnji_datum,broj_ocjena
    FROM ocjene
    WHERE ocjena = zadanaOcjena;

    RETURN CONCAT_WS(' ', 'Zadana ocjena=', zadanaOcjena, 'Broj ocjena=', broj_ocjena, 'Max datum=', zadnji_datum);
END #
DELIMITER ;

SELECT ocjenaStats(2)