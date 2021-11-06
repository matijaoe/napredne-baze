/* 1. Napisati proceduru koja će za zadanu šifru klijenta vratiti: jmbg
klijenta, ime i prezime klijenta, godinu unosa klijenta u sustav,
broj naloga koji se na njega odnose i sumu ostvarenih sati rada po nalozima za
tog klijenta. Prikazati i sveukupan broj sati za sve klijente preko izlaznog
parametra.
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/

DELIMITER //
DROP PROCEDURE IF EXISTS vratiNalogeSate;
CREATE PROCEDURE vratiNalogeSate(IN sifra INT, OUT sumaSati INT)
BEGIN
    SELECT k.jmbgKlijent,
           k.imeKlijent,
           k.prezimeKlijent,
           YEAR(k.datUnosKlijent) AS god_unosa,
           agr.broj_naloga,
           agr.suma_sati
    FROM (SELECT sifKlijent, SUM(OstvareniSatiRada) suma_sati, COUNT(*) broj_naloga
          FROM nalog n
          GROUP BY sifKlijent) agr
             JOIN klijent k ON k.sifKlijent = agr.sifKlijent
    WHERE k.sifKlijent = sifra;

    SELECT SUM(OstvareniSatiRada) ukupno_sati
    INTO sumaSati
    FROM nalog;
END //
DELIMITER ;

CALL vratiNalogeSate(1167, @tot_sati);
SELECT @tot_sati;

/* 2. Napisati proceduru koja će za zadanu šifru odjela i mjesec vratiti :
šifru radnika, ime i prezime radnika spojeno, broj_nalga, prosječne sate rada, koef plaće,
iznos osnovice te plaću na 2 decimale (plaća je umnožak osnovice i koef plaće).
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/
DELIMITER //
DROP PROCEDURE IF EXISTS vratiRadnikeOdjela;
CREATE PROCEDURE vratiRadnikeOdjela(IN zadanaSifra INT, IN bezMjeseca INT)
BEGIN
    SELECT r.sifRadnik,
           CONCAT_WS(' ', r.imeRadnik, r.prezimeRadnik) AS IME_PREZIME,
           n_agr.broj_naloga,
           n_agr.prosj_sati,
           r.KoefPlaca,
           r.IznosOsnovice,
           ROUND(r.IznosOsnovice * r.KoefPlaca, 2)      AS placa
    FROM (SELECT sifRadnik, COUNT(*) broj_naloga, AVG(OstvareniSatiRada) AS prosj_sati
          FROM nalog
          WHERE MONTH(datPrimitkaNalog) <> bezMjeseca
          GROUP BY sifRadnik
         ) n_agr
             JOIN radnik r ON r.sifRadnik = n_agr.sifRadnik
             JOIN odjel o ON r.sifOdjel = o.sifOdjel
    WHERE o.sifOdjel = zadanaSifra;
END //
DELIMITER ;

CALL vratiRadnikeOdjela(2, 7);


/* 3. Napisati proceduru koja će za zadani raspon prosječnih ocjena (ocjena_od,
ocjena_do) prikazati po kolegijima sljedeće podatke:
naziv kolegija, id smjera kojem kolegij pripada, id kolegija, broj položenih ispita i
prosječnu ocjenu kolegija
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/
DELIMITER //
DROP PROCEDURE IF EXISTS vratiKolegije;
CREATE PROCEDURE vratiKolegije(IN od DOUBLE, IN do DOUBLE)
BEGIN
    SELECT k.naziv, k.idSmjer, agr.*
    FROM (SELECT o.idKolegij, COUNT(*) broj_ispita, AVG(ocjena) prosj_ocjena
          FROM ocjene o
          GROUP BY o.idKolegij
          HAVING prosj_ocjena BETWEEN od AND do
         ) agr
             JOIN kolegiji k ON k.id = agr.idKolegij
    ORDER BY prosj_ocjena;
END //
DELIMITER ;

CALL vratiKolegije(2.2, 3.3);


/* 4. Napisati funkciju koja će za zadanu šifru kvara ispisati koliko je bilo naloga
po toj šifri kvara, prema sljedećem formatu. 'Broj naloga je: n.'
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/
DELIMITER //
DROP FUNCTION IF EXISTS brojiNaloge;
CREATE FUNCTION brojiNaloge(trazenaSifra INT) RETURNS VARCHAR(50)
    DETERMINISTIC
BEGIN
    DECLARE broj_naloga varchar(50) DEFAULT NULL;
    SELECT COUNT(*)
    INTO broj_naloga
    FROM nalog
    WHERE sifKvar = trazenaSifra;

    RETURN CONCAT('Broj naloga je: ', broj_naloga);
END //
DELIMITER ;

SELECT brojiNaloge(12) AS Broj;




