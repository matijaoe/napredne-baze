/* 1. Napisati proceduru koja će svim studentima koji su imali po kolegijima nepoložene ispita, dodati
iza prezimena oznaku " K N - OZNAKA", gdje je K šifra kolegija, N broj negativnih ocjena a oznaka je po sljedećem
formatu:
za 1 negativnu --> ' - ostalo 2 pokušaja '
za 2 negativne --> ' - ostao 1 pokušaj '
za 3 negativne --> '- komisijski ispit'
za više od 3 negativne --> '- ponovni upis kolegija'
Procedura mora vratiti broj n-torki koje je dohvatila.
Zadatak riješiti pomoću kursora. Napisati primjer poziva procedure.*/

DELIMITER ##
DROP PROCEDURE IF EXISTS mark_negativne;
CREATE PROCEDURE mark_negativne()
BEGIN
    DECLARE br_redova int DEFAULT 0;
    DECLARE c_jmbag char(10) DEFAULT NULL;
    DECLARE c_id_kol, c_br_neg int DEFAULT NULL;
    DECLARE c_oznaka varchar(50) DEFAULT NULL;
    DECLARE kraj BOOLEAN DEFAULT FALSE;
    DECLARE kur CURSOR FOR (
        SELECT jmbagStudent,
               idKolegij,
               COUNT(*)                           br_neg,
               CASE
                   WHEN COUNT(*) = 1 THEN 'ostalo 2 pokušaja'
                   WHEN COUNT(*) = 2 THEN 'ostao 1 pokušaj'
                   ELSE 'komisijski ispit' END AS oznaka
        FROM ocjene o
        WHERE ocjena = 1
        GROUP BY jmbagStudent, idKolegij
    );
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj = TRUE;


    OPEN kur;
    SELECT FOUND_ROWS() INTO br_redova;
    petlja:
    LOOP
        FETCH kur INTO c_jmbag, c_id_kol, c_br_neg, c_oznaka;

        IF kraj = TRUE THEN
            LEAVE petlja;
        END IF;

        UPDATE studenti
        SET prezime = CONCAT(prezime, ' Kol=', c_id_kol, ' Br_neg=', c_br_neg, ' - ', c_oznaka)
        WHERE c_jmbag = jmbag;

    END LOOP;

    CLOSE kur;

    SELECT br_redova AS 'Broj dohvacenih';
END ##
DELIMITER ;

CALL mark_negativne();


/* 2. Napisati proceduru koja će za zadana 2 kvartala prikazati sve odjele koji su ostvarili ili sumu sati između 20 i
50 ili imali više od 5 naloga. Ako je suma sati veća od 50 postaviti naziv odjela na velika slova.
Prikazati id odjela, naziv odjela, sumu ostvarenih sati, standardnu devijaciju ostvarenih sati i broj naloga.
Sortirati po Sumi sati padajući.
Zadatak riješiti pomoću kursora i privremene tablice. Napisati primjer poziva procedure.*/
DELIMITER ##
DROP PROCEDURE IF EXISTS nalozi_kvartal;
CREATE PROCEDURE nalozi_kvartal(kv1 INT, kv2 int)
BEGIN
    DECLARE br_redova int DEFAULT 0;
    DECLARE c_id_odj, c_br_nal INT DEFAULT NULL;
    DECLARE c_naziv_odj varchar(50) DEFAULT NULL;
    DECLARE c_suma_sati, c_stdev decimal(8, 2) DEFAULT NULL;
    DECLARE kraj BOOLEAN DEFAULT FALSE;
    DECLARE kur CURSOR FOR (
        SELECT o.sifOdjel,
               o.nazivOdjel,
               SUM(OstvareniSatiRada)           suma_sati,
               ROUND(STD(OstvareniSatiRada), 2) stdev,
               COUNT(*)                         broj_naloga
        FROM nalog n
                 JOIN radnik r ON n.sifRadnik = r.sifRadnik
                 JOIN odjel o ON r.sifOdjel = o.sifOdjel
        WHERE QUARTER(datPrimitkaNalog) IN (kv1, kv2)
        GROUP BY o.sifOdjel, o.nazivOdjel
        HAVING suma_sati BETWEEN 20 AND 50
            OR broj_naloga > 5
        ORDER BY suma_sati DESC);
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj = TRUE;

    DROP TEMPORARY TABLE IF EXISTS tmp;
    CREATE TEMPORARY TABLE tmp
    (
        id_Odj    INT(11),
        naziv_Odj VARCHAR(50),
        SumSati   decimal(8, 2),
        StdSati
                  decimal(4, 2),
        brNal     INT(11)
    );

    OPEN kur;
    SELECT FOUND_ROWS() INTO br_redova;
    petlja:
    LOOP
        FETCH kur INTO c_id_odj, c_naziv_odj, c_suma_sati, c_stdev ,c_br_nal;

        IF kraj = TRUE THEN
            LEAVE petlja;
        END IF;

        INSERT INTO tmp
        VALUES (c_id_odj, IF(c_suma_sati > 50, UPPER(c_naziv_odj), c_naziv_odj), c_suma_sati, c_stdev, c_br_nal);
    END LOOP;

    SELECT * FROM tmp;
    CLOSE kur;
END ##
DELIMITER ;

CALL nalozi_kvartal(1, 2);