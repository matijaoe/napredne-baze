/* 1. Napisati proceduru koja će za zadanu oznaku radionice vratiti: oznaku radionice, šifru i naziv rezerviranih
kvarova kao i broj kao radnika i broj sati kvara predviđenih za kvarove zadane radionice.
Preko izlaznog parametra treba vratiti ukupan predviđen kapacitet radnika za zadanu radionicu. Napisati smisleni
primjer poziva ovog pohranjenog zadatka.*/
DELIMITER ##
DROP PROCEDURE IF EXISTS vratiRadionicu;
CREATE PROCEDURE vratiRadionicu(IN ozn_rad varchar(50), OUT uk_kapacitet int)
BEGIN
    SELECT oznRadionica, k.sifKvar, k.nazivKvar, k.brojRadnika, k.satiKvar
    FROM rezervacija
             JOIN kvar k ON rezervacija.sifKvar = k.sifKvar
    WHERE oznRadionica = ozn_rad;

    SELECT SUM(r.kapacitetRadnika)
    INTO uk_kapacitet
    FROM radionica r;
END ##
DELIMITER ;

CALL vratiRadionicu('R10', @tot_kapacitet);
SELECT @tot_kapacitet;


/* 2. Napisati proceduru koja će za zadani ID smjera prikazati podatke po studentima koji su na ispitima dobili
ocjene 1 ili 2 te da im je prosjek tih ocjena veći od 1.
Prikazati sljedeće podatke:
id i naziv smjera, jmbag studenta, broj ispita, prosječnu ocjenu prema zadanom kriteriju.
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/
DELIMITER ##
DROP PROCEDURE IF EXISTS vratiPodatkeOStudentima;
CREATE PROCEDURE vratiPodatkeOStudentima(IN zadaniSmjerId int)
BEGIN
    SELECT sm.id, sm.naziv, agr.jmbag, broj_ispita, prosjek
    FROM (SELECT s.idSmjer, s.jmbag, AVG(ocjena) AS prosjek, COUNT(*) broj_ispita
          FROM ocjene
                   JOIN studenti s ON ocjene.jmbagStudent = s.jmbag
          WHERE ocjena IN (1, 2)
            AND s.idSmjer = zadaniSmjerId
          GROUP BY s.idSmjer, s.jmbag
          HAVING prosjek > 1
         ) agr
             JOIN smjerovi sm ON agr.idSmjer = sm.id;
END ##
DELIMITER ;

CALL vratiPodatkeOStudentima(1);

/* 3. Napisati funkciju koja će za zadani prioritet naloga ispisati koliko je bilo takvih naloga i njihov
prosječan broj sati ( na 2 decimale), prema sljedećem formatu. 'Broj naloga=n Prosjek sati=x' */
DELIMITER ##
DROP FUNCTION IF EXISTS vratiPodatkeNaloga;
CREATE FUNCTION vratiPodatkeNaloga(zadaniPrioritet INT) RETURNS VARCHAR(50)
    DETERMINISTIC
BEGIN
    DECLARE broj_naloga int;
    DECLARE prosjek_sati float;

    SELECT COUNT(*), ROUND(AVG(OstvareniSatiRada), 2)
    INTO broj_naloga, prosjek_sati
    FROM nalog
    WHERE prioritetNalog = zadaniPrioritet;

    RETURN CONCAT('Broj naloga=', broj_naloga, ' Prosjek sati=', prosjek_sati);
END ##
DELIMITER ;

SELECT vratiPodatkeNaloga(2) AS nalog_stats;


/* 4. Napisati funkciju koja će za zadani Id županije prikazati id županije, naziv županije i broj nastavnika iz te
županije, prema sljedećem formatu:
'Zadani Id županije=', idZup, ' Naziv županije=', naz_zup, ' Broj nastavnika =' , broj_nastavnika' */
DELIMITER ##
DROP FUNCTION IF EXISTS nastavniciZupanije;
CREATE FUNCTION nastavniciZupanije(zadaniIdZupanije INT) RETURNS VARCHAR(200)
    DETERMINISTIC
BEGIN
    DECLARE id_zup ,broj_nastavnika int DEFAULT NULL;
    DECLARE naz_zup varchar(100) DEFAULT NULL;

    SELECT z.id, z.nazivZupanija, COUNT(*)
    INTO id_zup, naz_zup, broj_nastavnika
    FROM nastavnici
             JOIN mjesta m ON nastavnici.postBr = m.postbr
             JOIN zupanije z ON z.id = m.idZupanija
    WHERE m.idZupanija = zadaniIdZupanije
    GROUP BY z.id, z.nazivZupanija;

    RETURN CONCAT('Zadani Id županije=', id_zup, ' Naziv županije=', naz_zup, ' Broj nastavnika =', broj_nastavnika);
END ##
DELIMITER ;

SELECT nastavniciZupanije(21) AS nalog_stats;



/* 5. Napisati proceduru koja će za zadani kvartal prikazati podatke po kolegijima. Izuzeti negativne ocjene
i kolegije koji su imali samo 1 položeni ispit.
Prikazati sljedeće podatke:
id i naziv kolegija, opis kolegija (prvih 100 znakova), min i max ocjenu te broj ispita. Sort po ID i nazivu kolegija.
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/
# Procedure
DELIMITER ##
DROP PROCEDURE IF EXISTS Kolegiji_po_kvartalu;
CREATE PROCEDURE Kolegiji_po_kvartalu(IN kvartal int)
BEGIN
    SELECT k.id, k.naziv, CONCAT(LEFT(k.opis, 100), '...'), min_ocj, max_ocj, broj_ispita
    FROM (SELECT idKolegij, COUNT(*) broj_ispita, MIN(ocjena) min_ocj, MAX(ocjena) max_ocj
          FROM ocjene
          WHERE QUARTER(datumPolaganja) = kvartal
            AND ocjena <> 1
          GROUP BY idKolegij
          HAVING broj_ispita > 1) agr
             JOIN kolegiji k ON agr.idKolegij = k.id
    ORDER BY 1, 2;
END ##
DELIMITER ;

CALL Kolegiji_po_kvartalu(3);

/* 6. Napisati proceduru koja će za zadani pbr klijenta prikazati sljedeće podatke po klijentima iz tog mjesta.
šifra klijenta, ime i prezime spojeno, godinu unosa klijenta, broj odrađenih naloga, sumu ostvarenih sati.
Odabrati klijente s više od jednog naloga i sortirati po sumi sati rada padajući.
Id i naziv županije vratiti preko jednog izlaznog parametra.
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/
# Procedure
DELIMITER ##
DROP PROCEDURE IF EXISTS Klijenti_iz_zupanije;
CREATE PROCEDURE Klijenti_iz_zupanije(IN zadaniPbr int, OUT naziv_zup varchar(50))
BEGIN
    SELECT CONCAT_WS(' ', imeKlijent, prezimeKlijent) ime_prezime,
           YEAR(datUnosKlijent)                       god_unosa,
           agr.br_naloga,
           agr.suma_sati
    FROM (SELECT n.sifKlijent, COUNT(*) br_naloga, SUM(OstvareniSatiRada) suma_sati
          FROM nalog n
                   JOIN klijent k ON n.sifKlijent = k.sifKlijent
          GROUP BY n.sifKlijent
          HAVING br_naloga > 1) agr
             JOIN klijent k ON agr.sifKlijent = k.sifKlijent
    WHERE k.pbrKlijent = zadaniPbr
    ORDER BY agr.suma_sati DESC;

    SELECT CONCAT_WS(' ', m.pbrMjesto, nazivZupanija)
    INTO naziv_zup
    FROM zupanija
             JOIN mjesto m ON zupanija.sifZupanija = m.sifZupanija
    WHERE m.pbrMjesto = zadaniPbr;
END ##
DELIMITER ;

CALL Klijenti_iz_zupanije(20000, @zup);
SELECT @zup;

/* 7. Napisati proceduru koja će za zadani kvartal prikazati podatke po kvarovima. Izuzeti prioritet 4
i kvarove koji su imali samo 1 nalog.
Prikazati sljedeće podatke:
sifru i naziv kvara, broj radnika za kvar, minimalni prioritet i broj naloga. Sort po šifri i nazivu kvara.
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/
DELIMITER ##
DROP PROCEDURE IF EXISTS kvaroviPoKvartalu;
CREATE PROCEDURE kvaroviPoKvartalu(IN zadani_kvartal INT)
BEGIN
    SELECT k.sifKvar, k.nazivKvar, k.brojRadnika, agr.min_prio, agr.br_naloga
    FROM (SELECT sifKvar, COUNT(*) br_naloga, MIN(prioritetNalog) min_prio
          FROM nalog
          WHERE QUARTER(datPrimitkaNalog) = zadani_kvartal
            AND prioritetNalog <> 4
          GROUP BY sifKvar
          HAVING br_naloga <> 1) agr
             JOIN kvar k ON k.sifKvar = agr.sifKvar
    ORDER BY k.sifKvar, k.nazivKvar;
END ##
DELIMITER ;

CALL kvaroviPoKvartalu(2);

/* 8. Napisati proceduru koja će za zadani pbr prebivanja studenata prikazati sljedeće podatke o tim studentima.
Jmbag, ime i prezime, pbr prebivanja, pbr stanovanja, broj položenih ispita, pros ocjenu položenih ispita.
Odabrati studente s više od jednog položenog ispita i prosjekom položenih ispita između 2 i 4.
Naziv mjesta prebivanja vratiti preko izlaznog parametra. Sort po prezimenu i imenu.
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/
DELIMITER ##
DROP PROCEDURE IF EXISTS podOStudentu;
CREATE PROCEDURE podOStudentu(IN trazeniPostBr INT, OUT mj_prebivanja varchar(100))
BEGIN
    SELECT s.jmbag, s.ime, s.prezime, s.postBrStanovanja, agr.broj_ispita, agr.prosjek
    FROM (SELECT o.jmbagStudent, COUNT(*) broj_ispita, ROUND(AVG(ocjena), 2) prosjek
          FROM ocjene o
          GROUP BY o.jmbagStudent
          HAVING broj_ispita > 1
             AND prosjek BETWEEN 2 AND 4) agr
             JOIN studenti s ON s.jmbag = agr.jmbagStudent
    WHERE s.postBrPrebivanje = trazeniPostBr
    ORDER BY 3, 2;

    SELECT nazivMjesto
    INTO mj_prebivanja
    FROM mjesta
    WHERE postbr = trazeniPostBr;
END ##
DELIMITER ;

CALL podOStudentu(32000, @mjesto);
SELECT @mjesto;