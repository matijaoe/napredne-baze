/*U bazi radionice: Po mjestima prebivanja klijenata i godinama ispisati ukupan broj odrađenih naloga te sumu ostvarenih sati  rada.
U rezultatu neka se pojave samo oni retci  koji su imali više od 5 naloga.

Prikazati sljedeće podatke: naziv mjesta, godinu, pbr klijenta, broj naloga i
sumu sati. Rezultate je potrebno sortirati po broju naloga padajući, prikazati prvih 10.*/

SELECT m.nazivMjesto, agr.godina, m.pbrMjesto, br_nal, suma_sati
FROM (SELECT m.pbrMjesto, YEAR(datPrimitkaNalog) godina, COUNT(*) br_nal, SUM(OstvareniSatiRada) suma_sati
      FROM nalog n
               JOIN klijent k ON n.sifKlijent = k.sifKlijent
               JOIN mjesto m ON k.pbrReg = m.pbrMjesto
      GROUP BY m.pbrMjesto, YEAR(datPrimitkaNalog)
      HAVING br_nal > 5) agr
         JOIN mjesto m ON agr.pbrMjesto = m.pbrMjesto
ORDER BY br_nal DESC;



-- KURSORI
/* 6. Napisati funkciju koja za zadani šifru kvara označava sve klijente čiji je udio
ostvarenih sati rada u ukupnim satima (za taj kvar) veći od 5%. Ako šifra kvara nije u tbl
NALOZI vraća poruku o nepostojanju šifre.
Klijente označava tako da im iza prezimena doda oznaku ' VIP - % udio= ' i iznos udjela u %.
Funkcija mora vratiti broj klijenata koje je dohvatila i obradila.
Zadatak riješiti pomoću kursora. Napisati primjer poziva procedure.*/
DELIMITER ##
DROP FUNCTION IF EXISTS oznaciKlijenteZad6;
CREATE FUNCTION oznaciKlijenteZad6(zadaniKvar INT) RETURNS VARCHAR(50)
    DETERMINISTIC
BEGIN
    DECLARE dohvaceno, obradeno int DEFAULT 0;
    DECLARE c_sifra, c_udio INT DEFAULT NULL;
    DECLARE kraj BOOLEAN DEFAULT FALSE;
    DECLARE kur CURSOR FOR (
        SELECT sifKlijent,
               SUM(OstvareniSatiRada) / (SELECT SUM(OstvareniSatiRada) FROM nalog WHERE sifKvar = zadaniKvar) * 100 udio
        FROM nalog
        WHERE sifKvar = zadaniKvar
        GROUP BY sifKlijent
        HAVING udio > 5
    );
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj = TRUE;

    IF zadaniKvar NOT IN (SELECT DISTINCT sifKvar FROM nalog) THEN
        RETURN 'Sifra ne postoji';
    END IF;

    OPEN kur;
    SELECT FOUND_ROWS() INTO dohvaceno;

    petlja:
    LOOP
        FETCH kur INTO c_sifra, c_udio;

        IF kraj = TRUE THEN
            LEAVE petlja;
        END IF;

        UPDATE klijent SET prezimeKlijent = CONCAT(prezimeKlijent, ' VIP - % udio=', c_udio) WHERE sifKlijent = c_sifra;

        SET obradeno = obradeno + 1;

    END LOOP;

    CLOSE kur;

    RETURN CONCAT('dohvaceno=', dohvaceno, ' | obradeno=', obradeno);

END ##
DELIMITER ;

SELECT oznaciKlijenteZad6(21);

/* Napisati proceduru koja će za zadani kvartal prikazati podatke po
kolegijima. Izuzeti negativne ocjene i kolegije koji su imali samo 1 položeni
ispit. Prikazati sljedeće podatke: id i naziv kolegija, prosječnu ocjenu
kolegija, min i max ocjenu, broj ispita te oznaku prosjeka "AVG iznad 3.00"
ili "AVG ispod 3.00". Sort po prosječnoj ocjeni rastući. Zadatak riješiti
pomoću kursora i privremene tablice. Napisati primjer poziva procedure.
 */

DELIMITER ##
DROP PROCEDURE IF EXISTS dajOcjeneZaKvartal;
CREATE PROCEDURE dajOcjeneZaKvartal(zadaniKvartal INT)
BEGIN
    DECLARE c_id, c_min_ocj, c_max_ocj, c_br_ispita INT DEFAULT NULL;
    DECLARE c_prosjek decimal(3, 2) DEFAULT NULL;
    DECLARE c_naziv, c_oznaka varchar(255) DEFAULT NULL;
    DECLARE kraj BOOLEAN DEFAULT FALSE;
    DECLARE kur CURSOR FOR (
        SELECT k.id,
               k.naziv,
               pros_ocj,
               min_ocj,
               max_ocj,
               br_ispita,
               IF(pros_ocj > 3, 'AVG iznad 3.00', 'AVG ispod 3.00') oznaka
        FROM (SELECT idKolegij,
                     ROUND(AVG(ocjena), 2) pros_ocj,
                     MIN(ocjena)           min_ocj,
                     MAX(ocjena)           max_ocj,
                     COUNT(*)              br_ispita
              FROM ocjene o
              WHERE QUARTER(datumPolaganja) = zadaniKvartal
                AND ocjena <> 1
              GROUP BY idKolegij
              HAVING br_ispita > 1
             ) agr
                 JOIN kolegiji k
                      ON agr.idKolegij = k.id
        ORDER BY pros_ocj
    );
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj = TRUE;

    DROP TEMPORARY TABLE IF EXISTS temp_table;
    CREATE TEMPORARY TABLE temp_table
    (
        id       INT,
        naziv    VARCHAR(255),
        prosjek  DECIMAL(3, 2),
        minOcj   INT,
        maxOcj   INT,
        brIspita INT,
        oznaka   varchar(255)
    );

    OPEN kur;

    petlja:
    LOOP
        FETCH kur INTO c_id, c_naziv, c_prosjek, c_min_ocj, c_max_ocj, c_br_ispita, c_oznaka;

        IF kraj = TRUE THEN
            LEAVE petlja;
        END IF;

        INSERT INTO temp_table
        VALUES (c_id, c_naziv, c_prosjek, c_min_ocj, c_max_ocj, c_br_ispita, c_oznaka);
    END LOOP;

    SELECT * FROM temp_table;
    CLOSE kur;
END ##
DELIMITER ;

CALL dajOcjeneZaKvartal(1);


-- kontrola toka
/* 2. Napisati proceduru koja će za zadanu šifru radnika preko izlaznih parametara ispisati:
ime i prezime radnika, broj naloga koje je odradio kao i broj RAZLIČITIH klijenata za koje je
taj radnik odradio naloge.
Ako nema tražene šifre u nalozima vraća poruku: "Nepostojeća šifra radnika". Koristiti
CASE WHEN … strukturu za uvjet!
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/
DELIMITER ##
DROP PROCEDURE IF EXISTS ispisiRadnike;
CREATE PROCEDURE ispisiRadnike(zadanaSifra INT, OUT imePrez varchar(255), OUT brNal int, OUT brKlij int)
BEGIN
    CASE WHEN zadanaSifra IN (SELECT sifRadnik FROM nalog) THEN
        SELECT r.sifRadnik,
               CONCAT_WS(' ', r.imeRadnik, r.prezimeRadnik),
               COUNT(*)                   br_naloga,
               COUNT(DISTINCT sifKlijent) br_klijenata
        INTO zadanaSifra, imePrez, brNal, brKlij
        FROM nalog n
                 JOIN radnik r ON n.sifRadnik = r.sifRadnik
        WHERE n.sifRadnik = zadanaSifra
        GROUP BY r.sifRadnik;
        ELSE
            SELECT 'Nepostojeća šifra radnika';
        END CASE;
END ##
DELIMITER ;

CALL ispisiRadnike(122, @imprez, @brn, @brk);
SELECT @imprez, @brn, @brk;
