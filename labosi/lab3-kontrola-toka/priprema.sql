/* 1. Napisati funkciju koja će za zadanu ocjenu vratiti broj studenata koji su
ocijenjeni s tom ocjenom. Ocjena koja se unosi mora biti u opsegu 1 - 5. Ako se
kao ulaz u funkciju zada ocjena izvan opsega, funkcija treba vratiti poruku:
'Neispravno unesena ocjena.', a ako je ocjena ispravna, funkcija treba vratiti:
'Ocjenom X ocijenjeno Y studenata' ('X' i 'Y' zamijeniti s odgovarajućim
vrijednostima).
Napisati smisleni primjer poziva ovog pohranjenog zadatka. */
DELIMITER ##
DROP FUNCTION IF EXISTS brojOcjena;
CREATE FUNCTION brojOcjena(zadana_ocjena INT) RETURNS VARCHAR(50)
    DETERMINISTIC
BEGIN
    DECLARE broj_studenata int DEFAULT NULL;
    IF zadana_ocjena NOT BETWEEN 1 AND 5 THEN
        RETURN 'Neispravno unesena ocjena';
    ELSE
        SELECT COUNT(DISTINCT jmbagStudent)
        INTO broj_studenata
        FROM ocjene
        WHERE ocjena = zadana_ocjena;

        RETURN CONCAT_WS(' ', 'Ocjenom', zadana_ocjena, 'ocjenjeno je', broj_studenata, 'studenata');
    END IF;
END ##
DELIMITER ;

SELECT brojOcjena(3);
SELECT brojOcjena(8);


/* 2. Napisati proceduru koja za zadani odjel ispisuje radnike iz tog odjela tako
da ih sortira po najvećem prosječnom broju ostvarenih sati iz naloga uz oznaku je
li je prosjek sati dotičnog radnika po nalogu iznad/ispod prosjeka tog odjela.
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/
DELIMITER ##
DROP PROCEDURE IF EXISTS odjelRadnici;
CREATE PROCEDURE odjelRadnici(IN zadaniOdjel INT)
BEGIN
    DECLARE ukupan_prosjek decimal(6, 2);

    SELECT AVG(OstvareniSatiRada)
    INTO ukupan_prosjek
    FROM nalog n
             NATURAL JOIN radnik r
    WHERE r.sifOdjel = zadaniOdjel;

    SELECT r.sifRadnik,
           CONCAT_WS(' ', r.imeRadnik, r.prezimeRadnik)                                    imePrezime,
           AVG(OstvareniSatiRada) AS                                                       prosjek_sati,
           IF(AVG(OstvareniSatiRada) > ukupan_prosjek, 'iznad prosjeka', 'ispod prosjeka') oznaka
    FROM nalog
             NATURAL JOIN radnik r
    WHERE r.sifOdjel = zadaniOdjel
    GROUP BY r.sifRadnik, imePrezime
    ORDER BY 3 DESC;
END ##
DELIMITER ;

CALL odjelRadnici(2);


/* 3. Napisati funkciju koja će za zadanu šifru radnika ispisati njegovo ime
onoliko puta koliko ima znakova u tom imenu (odvojeno crticom).
Nakon zadnjeg ispisa imena ne smije biti crtica.
a) Napisati primjer poziva funkcije za jednog radnika
b) Napisati primjer poziva funkcije za sve radnike, sortirano abecedno po
imenu */
DELIMITER ##
DROP FUNCTION IF EXISTS printImeRadnika;
CREATE FUNCTION printImeRadnika(zadanaSifra INT) RETURNS VARCHAR(255)
    DETERMINISTIC
BEGIN
    DECLARE izlaz varchar(255) DEFAULT NULL;
    DECLARE ime_radnika varchar(100) DEFAULT NULL;
    DECLARE duljina_imena int DEFAULT NULL;
    DECLARE i int DEFAULT 0;

    SELECT imeRadnik, LENGTH(imeRadnik)
    INTO ime_radnika, duljina_imena
    FROM radnik
    WHERE sifRadnik = zadanaSifra;

    WHILE i < duljina_imena
        DO
            SET izlaz = CONCAT_WS(' - ', izlaz, ime_radnika);
            SET i = i + 1;
        END WHILE;

    RETURN izlaz;
END ##
DELIMITER ;

SELECT printImeRadnika(122);

SELECT sifRadnik, imeRadnik, printImeRadnika(sifRadnik)
FROM radnik;


/* 4. Napisati proceduru koja za zadani broj radnika i zadanu kategoriju plaće
ispisuje sve odjele u kojima radi taj broj radnika te primaju plaću u zadanoj
kategoriji. Za svaki odjel koji zadovoljava taj kriterij treba ispisati:
- broj radnika,
- kategoriju plaće,
- naziv odjela i
- prosječnu plaću.
Kategorije (A, B, C, D) se formiraju po sljedećim pravilima:
- 'A' - radnici koji imaju plaću manju od 2500
- 'B' - radnici koji imaju plaću između 2500 i 3000
- 'C' - radnici koji imaju plaću između 3000.01 i 3500
- 'D' - radnici koji imaju plaćuveću od 3500
Sortirati po nazivu odjela rastući.
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/
DELIMITER ##
DROP PROCEDURE IF EXISTS kateogorijePlacaOdjel;
CREATE PROCEDURE kateogorijePlacaOdjel(IN zadaniBrRadnika INT, IN zadanaKatPlace CHAR(1))
BEGIN
    SELECT o.sifOdjel,
           COUNT(*)                                    broj_radnika,
           CASE
               WHEN
                   ROUND(AVG(IznosOsnovice * KoefPlaca), 2) < 2500 THEN 'A'
               WHEN
                   ROUND(AVG(IznosOsnovice * KoefPlaca), 2) BETWEEN 2500 AND 3000 THEN 'B'
               WHEN
                   ROUND(AVG(IznosOsnovice * KoefPlaca), 2) BETWEEN 3000.01 AND 3500 THEN 'C'
               ELSE
                   'D'
               END                                  AS Kategorija,
           o.nazivOdjel,
           ROUND(AVG(IznosOsnovice * KoefPlaca), 2) AS prosj_placa
    FROM radnik r
             NATURAL JOIN odjel o
    GROUP BY sifOdjel
    HAVING broj_radnika = zadaniBrRadnika
       AND Kategorija = zadanaKatPlace
    ORDER BY 1;
END ##
DELIMITER ;

CALL kateogorijePlacaOdjel(2, 'D');
SELECT @a;


/* 5. Napisati proceduru koja za odabrani period (godina OD i godina DO)
prikazuje troškove autoradionice po godinama i mjesecima. Trošak računati kao
umnožak broja radnika koji je radio u mjesecu i prosječne mjesečne plaće.
Potrebno je prikazati podatke prema slici.
Također treba osigurati da godina OD bude manja ili jednaka godini DO, da su
godine četveroznamenkaste i da je barem jedna u vremenu kada postoji zapis o
odrađenom nalogu. Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/
DELIMITER ##
DROP PROCEDURE IF EXISTS CostsYearMonth;
CREATE PROCEDURE CostsYearMonth(IN od INT, IN do INT, OUT msg varchar(100))
BEGIN
    IF od < do AND LENGTH(od) = 4 AND LENGTH(do) = 4 AND (od IN (SELECT DISTINCT YEAR(datPrimitkaNalog)
                                                                 FROM nalog) OR
                                                          do IN (SELECT DISTINCT YEAR(datPrimitkaNalog)
                                                                 FROM nalog)) THEN
        SELECT agr.*, agr.broj_radnika * agr.prosj_placa AS trosak
        FROM (SELECT YEAR(datPrimitkaNalog)                godina,
                     MONTH(datPrimitkaNalog)               mjesec,
                     COUNT(*)                              broj_radnika,
                     ROUND(AVG(KoefPlaca * IznosOsnovice)) prosj_placa
              FROM radnik r
                       JOIN nalog n ON r.sifRadnik = n.sifRadnik
              WHERE YEAR(datPrimitkaNalog) BETWEEN od AND do
              GROUP BY 1, 2
             ) agr
        ORDER BY 1, 2;

    ELSE
        SET msg = 'Godine nisu dobro definirane / nisu u traženom rasponu';
    END IF;
END ##
DELIMITER ;

CALL CostsYearMonth(2015, 2019, @msg);
SELECT @msg;