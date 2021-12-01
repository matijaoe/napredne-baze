/* 1. Napisati proceduru koja će za zadani prioritet prikazati sve odjele koji su ostvarili
više od jednog naloga. Pored traženih podataka, id odjela, naziv odjela, broja naloga i
prosječno ostvarenih sati, prikazati i tip odjela u smislu volumena tj. broja odrađenih
naloga koji može biti UNDER_VOLUME ako ima manje od 20 naloga i OVER_VOLUME ako
ima više ili jednako 20 naloga.
Zadatak riješiti pomoću kursora i privremene tablice. Napisati primjer poziva
procedure.*/
DELIMITER ##
DROP PROCEDURE IF EXISTS odjeli_naloz;
CREATE PROCEDURE odjeli_naloz(IN zadaniPrioritet INT)
BEGIN
    DECLARE c_id_odjel, c_br_naloga int DEFAULT NULL;
    DECLARE c_naziv_odjel varchar(100) DEFAULT NULL;
    DECLARE c_prosj_sati decimal(4, 2) DEFAULT 0;
    DECLARE n int DEFAULT 0;
    DECLARE br_redova int DEFAULT NULL;
    DECLARE kur CURSOR FOR (SELECT o.sifOdjel,
                                   o.nazivOdjel,
                                   COUNT(*)               broj_naloga,
                                   AVG(OstvareniSatiRada) prosjek_sati
                            FROM nalog n
                                     JOIN radnik r ON n.sifRadnik = r.sifRadnik
                                     JOIN odjel o ON r.sifOdjel = o.sifOdjel
                            WHERE prioritetNalog = zadaniPrioritet
                            GROUP BY o.sifOdjel, o.nazivOdjel
                            HAVING broj_naloga > 1
                            ORDER BY prosjek_sati DESC);
    DROP TEMPORARY TABLE IF EXISTS temp_odjel;
    CREATE TEMPORARY TABLE temp_odjel
    (
        id         int,
        naziv      varchar(100),
        br_naloga  INT,
        prosj_sati decimal(4, 2),
        tip        varchar(50)
    );

    OPEN kur;
    SELECT FOUND_ROWS() INTO br_redova;
    SELECT br_redova;

    WHILE n < br_redova
        DO
            FETCH kur INTO c_id_odjel, c_naziv_odjel, c_br_naloga, c_prosj_sati;
            INSERT INTO temp_odjel
            VALUES (c_id_odjel, c_naziv_odjel, c_br_naloga, c_prosj_sati,
                    IF(c_br_naloga, 'UNDER_VOLUME', 'OVER_VOLUME'));
            SET n = n + 1;
        END WHILE;

    SELECT * FROM temp_odjel;
    CLOSE kur;
END
##
DELIMITER ;

CALL odjeli_naloz(1);


/* 2. Napisati proceduru koja će svim kvarovima koji su imali manje od 10 odrađenih
naloga, smanjiti broj radnika (tablica KVAR) samo ako je postojeći broj radnika veći od 1.
Procedura mora vratiti broj n-torki koje je dohvatila i obradila.
Zadatak riješiti pomoću kursora. Napisati primjer poziva procedure.*/
DELIMITER ##
DROP PROCEDURE IF EXISTS korigiraj_radnik;
CREATE PROCEDURE korigiraj_radnik()
BEGIN
    DECLARE kraj BOOL DEFAULT FALSE;
    DECLARE c_sifra int DEFAULT NULL;
    DECLARE br_dohvacenih, br_obradenih int DEFAULT 0;
    DECLARE kur CURSOR FOR (SELECT k.sifKvar
                            FROM kvar k
                                     NATURAL JOIN nalog
                            WHERE k.brojRadnika > 1
                            GROUP BY k.sifKvar
                            HAVING COUNT(*) < 10
    );
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj = TRUE;

    OPEN kur;
    SELECT FOUND_ROWS() INTO br_dohvacenih;
    petlja:
    LOOP
        FETCH kur INTO c_sifra;
        IF kraj = TRUE THEN
            LEAVE petlja;
        END IF;

        UPDATE kvar k SET k.brojRadnika = k.brojRadnika - 1 WHERE sifKvar = c_sifra;
        SET br_obradenih = br_obradenih + 1;
    END LOOP;

    CLOSE kur;

    SELECT br_dohvacenih, br_obradenih;
END ##
DELIMITER ;

CALL korigiraj_radnik();


/* 3. Napisati proceduru koja će svim studentima koji su imali veći broj nepoloženih ispita
od položenih, dodati iza prezimena oznaku "x - n", gdje je n broj negativnih ocjena.
Označeni studenti moraju imati barem jedan nepoložen ispit.
Procedura mora vratiti broj n-torki koje je dohvatila i obradila.
Zadatak riješiti pomoću kursora. Napisati primjer poziva procedure.*/
DELIMITER ##
DROP PROCEDURE IF EXISTS mark_students;
CREATE PROCEDURE mark_students()
BEGIN
    DECLARE c_jmbag char(10) DEFAULT NULL;
    DECLARE c_neg, c_poz,br_obradenih, br_dohvacenih, i int DEFAULT 0;
    DECLARE kur CURSOR FOR (SELECT jmbagStudent,
                                   SUM(IF(ocjena = 1, 1, 0)) br_neg,
                                   SUM(IF(ocjena > 1, 1, 0)) br_poz
                            FROM ocjene o
                            GROUP BY jmbagStudent
                            HAVING br_neg > br_poz);

    OPEN kur;
    SELECT FOUND_ROWS() INTO br_dohvacenih;

    WHILE i < br_dohvacenih
        DO
            FETCH kur INTO c_jmbag, c_neg, c_poz;
            UPDATE studenti SET prezime = CONCAT(prezime, ' x - ', c_neg) WHERE jmbag = c_jmbag;
            SET br_obradenih = br_obradenih + 1;
            SET i = i + 1;

        END WHILE;

    SELECT br_dohvacenih, br_obradenih;
    CLOSE kur;
END ##
DELIMITER ;

CALL mark_students();

/* 4. Napisati proceduru koja će za zadanu godinu prikazati sljedeće podatke o kvarovima:
šifra kvara, naziv kvara, broj odrađenih kvarova, sumu ostv. sati kao i nominalne podatke
iz tablice KVAR (satiKvar i brojRadnika). Prikazati samo kvarove ako imaju više od jednog
naloga.
Zadatak riješiti pomoću kursora i privremene tablice. Napisati primjer poziva
procedure.*/
DELIMITER ##
DROP PROCEDURE IF EXISTS kvarovi_nalozi;
CREATE PROCEDURE kvarovi_nalozi(IN zadanaGodina INT)
BEGIN
    DECLARE c_sifKvar, c_suma_sati, c_satiKvar, c_brojRadnika, c_br_kvarova int DEFAULT NULL;
    DECLARE c_nazivKvar varchar(255) DEFAULT NULL;
    DECLARE kraj boolean DEFAULT FALSE;
    DECLARE kur CURSOR FOR (
        SELECT k.sifKvar, k.nazivKvar, suma_sati, k.satiKvar, k.brojRadnika, br_kvarova
        FROM (SELECT k.sifKvar, k.nazivKvar, SUM(OstvareniSatiRada) suma_sati, COUNT(*) br_kvarova
              FROM kvar k
                       NATURAL JOIN nalog n
              WHERE YEAR(n.datPrimitkaNalog) = zadanaGodina
              GROUP BY k.sifKvar
              HAVING br_kvarova > 1
             ) agr
                 JOIN kvar k ON agr.sifKvar = k.sifKvar);
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj = TRUE;

    DROP TEMPORARY TABLE IF EXISTS temp_table;
    CREATE TEMPORARY TABLE temp_table
    (
        sifKvar     INT,
        nazivKvar   VARCHAR(255),
        suma_sati   INT,
        br_kvarova  INT,
        satiKvar    INT,
        brojRadnika INT
    );

    OPEN kur;
    petlja:
    LOOP
        FETCH kur INTO c_sifKvar, c_nazivKvar, c_suma_sati, c_br_kvarova, c_satiKvar, c_brojRadnika;
        IF kraj = TRUE THEN
            LEAVE petlja;
        END IF;
        INSERT INTO temp_table
        VALUES (c_sifKvar, c_nazivKvar, c_suma_sati, c_br_kvarova, c_satiKvar, c_brojRadnika);
    END LOOP;

    SELECT * FROM temp_table;
    CLOSE kur;
END ##
DELIMITER ;

CALL kvarovi_nalozi(2016);


/* 5. Napisati funkciju koja za zadani smjer i oznaku smanjenja ('S') tj. povećanja ('P'),
smanjuje ili povećava sve ocjene studentima odabranog smjera. Ocjenu 1 ne može smanjiti
a ocjenu 5 ne može povećati. Oznake smanjenja/povećanja moraju biti slova S ili P (mala
ili velika).
Funkcija mora vratiti broj studenata koje je dohvatila i obradila (odvojeno smanenje /
povećanje).
Zadatak riješiti pomoću kursora. Napisati primjer poziva procedure.*/
DELIMITER ##
DROP FUNCTION IF EXISTS korigirajOcjene;
CREATE FUNCTION korigirajOcjene(zadanIdSmjera INT, oznaka char(1)) RETURNS VARCHAR(50)
    DETERMINISTIC
BEGIN
    DECLARE dohvaceno, smanjeno, povecano int DEFAULT 0;
    DECLARE c_jmbag varchar(50) DEFAULT NULL;
    DECLARE kraj boolean DEFAULT FALSE;
    DECLARE kur CURSOR FOR (SELECT s.jmbag
                            FROM studenti s
                                     JOIN ocjene o ON s.jmbag = o.jmbagStudent
                            WHERE s.idSmjer = zadanIdSmjera);
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj = TRUE;

    IF UPPER(oznaka) NOT IN ('S', 'P') THEN
        RETURN 'Neispravna oznaka smanjenja/povećanja.';
    END IF;

    OPEN kur;
    SELECT FOUND_ROWS() INTO dohvaceno;

    petlja:
    LOOP
        FETCH kur INTO c_jmbag;

        IF kraj = TRUE THEN
            LEAVE petlja;
        END IF;

        CASE WHEN UPPER(oznaka) = 'S' THEN
            UPDATE ocjene
            SET ocjena = ocjena - 1
            WHERE jmbagStudent = c_jmbag
              AND ocjena > 1;
            SET smanjeno = smanjeno + 1;

            WHEN UPPER(oznaka) = 'P' THEN
                UPDATE ocjene
                SET ocjena = ocjena + 1
                WHERE jmbagStudent = c_jmbag
                  AND ocjena < 5;
                SET povecano = povecano + 1;
            END CASE;
    END LOOP;

    CLOSE kur;

    RETURN CONCAT('Dohvaćeno: ', dohvaceno, ' Smanjeno: ', smanjeno, ' Povećano: ', povecano);
END ##
DELIMITER ;

SELECT korigirajOcjene(3, 'P');
SELECT korigirajOcjene(3, 'S');
SELECT korigirajOcjene(1, 'S');


/* 6. Napisati funkciju koja za zadani šifru kvara označava sve klijente čiji je udio
ostvarenih sati rada u ukupnim satima (za taj kvar) veći od 5%. Ako šifra kvara nije u tbl
NALOZI vraća poruku o nepostojanju šifre.
Klijente označava tako da im iza prezimena doda oznaku ' VIP - % udio= ' i iznos udjela u %.
Funkcija mora vratiti broj klijenata koje je dohvatila i obradila.
Zadatak riješiti pomoću kursora. Napisati primjer poziva procedure.*/
DELIMITER ##
DROP FUNCTION IF EXISTS oznaciKlijente;
CREATE FUNCTION oznaciKlijente(zadanaSifra INT) RETURNS VARCHAR(50)
    DETERMINISTIC
BEGIN
    DECLARE dohvaceno, obradeno int DEFAULT 0;
    DECLARE c_sif_klijent INT DEFAULT NULL;
    DECLARE c_udio decimal(4, 2) DEFAULT NULL;
    DECLARE kraj BOOLEAN DEFAULT FALSE;
    DECLARE kur CURSOR FOR (
        SELECT n.sifKlijent,
               SUM(n.OstvareniSatiRada) / (SELECT SUM(OstvareniSatiRada)
                                           FROM nalog
                                           WHERE sifKvar = zadanaSifra) udio
        FROM nalog n
                 JOIN klijent k ON n.sifKlijent = k.sifKlijent
        WHERE n.sifKvar = zadanaSifra
        GROUP BY n.sifKlijent
        HAVING udio > 0.05
    );
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj = TRUE;

    IF zadanaSifra NOT IN (SELECT DISTINCT sifKvar FROM nalog ORDER BY sifKvar) THEN
        RETURN 'Šifra kvara ne postoji';
    END IF;

    OPEN kur;
    SELECT FOUND_ROWS() INTO dohvaceno;

    petlja:
    LOOP
        FETCH kur INTO c_sif_klijent, c_udio;

        IF kraj = TRUE THEN
            LEAVE petlja;
        END IF;

        UPDATE klijent
        SET prezimeKlijent = CONCAT(prezimeKlijent, ' VIP - % udio= ', c_udio)
        WHERE sifKlijent = c_sif_klijent;

        SET obradeno = obradeno + 1;

    END LOOP;

    CLOSE kur;

    RETURN CONCAT('Dohvaceno: ', dohvaceno, ' | Obradeno: ', obradeno);
END ##
DELIMITER ;

SELECT oznaciKlijente(5);