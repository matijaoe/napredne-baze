/* 1. Napisati proceduru koja će za zadanu šifru kvara preko izlaznih
parametara ispisati: naziv kvara, broj naloga i broj RAZLIČITIH klijenata koji
su imali taj kvar.
Ako nema tražene šifre u nalozima vraća poruku: "Nepostojeća šifra kvara".
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/
DELIMITER ##
DROP PROCEDURE IF EXISTS ispisiZaKvar;
CREATE PROCEDURE ispisiZaKvar(IN zadana_sifra INT, OUT broj_naloga INT, OUT broj_klijenata INT,
                              OUT naziv_kvara varchar(100))
BEGIN

    IF zadana_sifra IN (SELECT DISTINCT sifKvar FROM kvar) THEN
        SELECT DISTINCT k.nazivKvar, COUNT(*)
        INTO naziv_kvara, broj_naloga
        FROM nalog n
                 NATURAL JOIN kvar k
        WHERE sifKvar = 10;

        SELECT COUNT(DISTINCT k.sifKlijent)
        INTO broj_klijenata
        FROM klijent k
                 JOIN nalog n ON k.sifKlijent = n.sifKlijent
        WHERE n.sifKvar = zadana_sifra;
    ELSE
        SELECT 'Nepostojeća šifra kvara' AS poruka;
    END IF;
END ##
DELIMITER ;

CALL ispisiZaKvar(11, @brojn, @brojk, @nazivk);
SELECT @brojn, @brojk, @nazivk;


/* 2. Napisati proceduru koja će za zadanu šifru radnika preko izlaznih parametara ispisati:
ime i prezime radnika, broj naloga koje je odradio kao i broj RAZLIČITIH klijenata za koje je
taj radnik odradio naloge.
Ako nema tražene šifre u nalozima vraća poruku: "Nepostojeća šifra radnika". Koristiti
CASE WHEN … strukturu za uvjet!
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/
DELIMITER ##
DROP PROCEDURE IF EXISTS brojiKvarove;
CREATE PROCEDURE brojiKvarove(IN zadanaSifra INT, OUT ime_prezime varchar(100), OUT broj_naloga int,
                              OUT broj_klijenata int)
BEGIN
    CASE WHEN zadanaSifra IN (SELECT sifRadnik
                              FROM radnik) THEN
        SELECT CONCAT_WS(' ', r.imeRadnik, r.prezimeRadnik),
               COUNT(*),
               COUNT(DISTINCT sifKlijent)
        INTO ime_prezime,broj_naloga,broj_klijenata
        FROM nalog
                 NATURAL JOIN radnik r
        WHERE r.sifRadnik = zadanaSifra
        GROUP BY 1;
        ELSE
            SELECT 'Nepostojeća šifra radnika' AS poruka;
        END CASE;
END ##
DELIMITER ;

CALL brojiKvarove(166, @radnik, @br_n, @br_kl);
SELECT @radnik, @br_n, @br_kl;


/* 3. Napisati funkciju koja za zadanu šifru klijenta prikazuje njegovo ime i prezime
onoliko puta koliko je taj klijent imao naloga(odvojenih crticom). Na kraju nema
crtice.
Ukoliko zadana šifra klijenta ne postoji u tablici NALOG, funkcija vraća poruku:
"Nepostojeća šifra klijenta".
Napisati primjer poziva funkcije za jednog klijenta*/
DELIMITER ##
DROP FUNCTION IF EXISTS zadatak3;
CREATE FUNCTION zadatak3(zadanaSifra INT) RETURNS VARCHAR(300)
    DETERMINISTIC
BEGIN
    DECLARE broj_naloga INT DEFAULT NULL;
    DECLARE n INT DEFAULT 0;
    DECLARE poruka VARCHAR(300) DEFAULT NULL;
    DECLARE ime_prezime VARCHAR(30) DEFAULT NULL;

    IF zadanaSifra IN (SELECT sifKlijent FROM nalog WHERE sifKlijent = zadanaSifra) THEN

        SELECT COUNT(*)
        INTO broj_naloga
        FROM nalog
        WHERE sifKlijent = zadanaSifra;

        SELECT CONCAT_WS(' ', imeKlijent, prezimeKlijent) INTO ime_prezime FROM klijent WHERE sifKlijent = zadanaSifra;

        WHILE n < broj_naloga
            DO
                SET poruka = CONCAT_WS(' - ', poruka, ime_prezime);
                SET n = n + 1;
            END WHILE;
    ELSE
        SET poruka = 'Nepostojeća šifra klijenta';
    END IF;

    RETURN poruka;
END ##
DELIMITER ;

SELECT zadatak3(1133);


/* 6. Napisati proceduru koja za zadanu šifru smjera ispisuje studente s tog
smjera na način da ih sortira po najvećoj prosječnoj ocjeni i nakon toga po
broju ispita uz oznaku (flag) da li je prosjek studenta iznad/ispod prosjeka
tog
smjera. Prilikom ispisa, dodatno je potrebno konkatenirati ime i prezime
studenta.
Ako nema tražene šifre u tablici SMJEROVI vraća poruku: "Nepostojeća šifra
smjera". Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/
DELIMITER ##
DROP PROCEDURE IF EXISTS zad6;
CREATE PROCEDURE zad6(zadanaSifraSmjera int)
BEGIN
    DECLARE prosjek_smjera int DEFAULT NULL;

    IF zadanaSifraSmjera IN (SELECT id FROM smjerovi) THEN

        SELECT AVG(ocjena)
        INTO prosjek_smjera
        FROM ocjene o
                 JOIN kolegiji k ON o.idKolegij = k.id
        WHERE idSmjer = zadanaSifraSmjera;


        SELECT o.jmbagStudent,
               CONCAT_WS(' ', s.ime, s.prezime)                                     ime_prezime,
               AVG(ocjena)                                                          prosjek,
               COUNT(*)                                                             broj_ispita,
               IF(AVG(ocjena) > prosjek_smjera, 'Iznad prosjeka', 'Ispod prosjeka') flag
        FROM ocjene o
                 JOIN studenti s ON o.jmbagStudent = s.jmbag
        WHERE idSmjer = zadanaSifraSmjera
        GROUP BY 1, 2
        ORDER BY prosjek DESC, broj_ispita DESC;
    ELSE
        SELECT 'Nepostojeća šifra smjera';
    END IF;
END ##
DELIMITER ;

CALL zad6(1);


/* 7. Napisati proceduru koja za zadani OIB ustanove prikazuje u vidu MATRICE
nazive smjerova i koliko je svaki smjer dobio ocjena, za svaku ocjenu (1-5)
pojedinačno. Prikazati i prosječnu ocjenu smjera kao i standardnu devijaciju.
Ukoliko zadani OIB ne postoji u tablici USTANOVE, procedura vraća poruku:
"Nepostojeći OIB ustanove.".
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/
DELIMITER //
DROP PROCEDURE IF EXISTS Ustanove //
CREATE PROCEDURE Ustanove(IN oib_u CHAR(11) )
BEGIN
    IF oib_u IN (SELECT oib FROM ustanove)
    THEN
        SELECT s.id, s.naziv,
               SUM(CASE WHEN o.ocjena=1 THEN 1 ELSE 0 END ) AS OC_1,
-- Count(CASE WHEN o.ocjena=1 THEN 900 ELSE null END) AS OC_1_1,
               SUM(CASE WHEN o.ocjena=2 THEN 1 ELSE 0 END ) AS OC_2,
               SUM(CASE WHEN o.ocjena=3 THEN 1 ELSE 0 END ) AS OC_3,
               SUM(CASE WHEN o.ocjena=4 THEN 1 ELSE 0 END ) AS OC_4,
               SUM(CASE WHEN o.ocjena=5 THEN 1 ELSE 0 END ) AS OC_5,
               ROUND(AVG(o.ocjena),2) AS AVG_smjera,
               ROUND(STD(o.ocjena),2) AS STD_smjera
        FROM smjerovi s INNER JOIN kolegiji k ON s.id = k.idSmjer
                        INNER JOIN ocjene o ON k.id = o.idKolegij
        WHERE s.oibUstanova = oib_u
        GROUP BY s.id, s.naziv
        ORDER BY 7 DESC ;
    ELSE SELECT 'Nepostojeći OIB ustanove. ' AS Poruka;
    END IF;
END;
//
DELIMITER ;
/*Poziv procedure*/
CALL Ustanove('08814003451');
CALL Ustanove('99999999999');