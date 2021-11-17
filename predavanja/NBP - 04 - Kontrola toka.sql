/*******KONTROLA TOKA U UPITIMA*********/

/*Izraditi popis svih studenata sortiran abecedno po prezimenu uz napomenu radi li se o studentu koji je domaći ili putnik. Kriterij student se smatra putnikom ako ne prebiva u mjestu stanovanja, odnosno u suprotnom se smatra domaćim.*/

SELECT `jmbag`,
       `prezime`,
       `ime`,
       IF(`postBrPrebivanje` = `postBrStanovanja`, 'domaći', 'putnik')
           AS oznaka
FROM studenti
ORDER BY prezime;


/*Izraditi popis svih kolegija na Tehničkom veleučilištu u Zagrebu sa prosječnim ocjenama na kolegiju i s nazivom smjera kojem kolegij pripada.
Ako kolegij ima prosječnu ocjenu 4.5 ili veću, potrebno je ispisati napomenu ‘kolegij s izvrsnim prosjekom’.*/

SELECT kolegiji.naziv,
       smjerovi.naziv,
       AVG(ocjena)                                                  prosjecna_ocjena,
       IF(AVG(ocjena) >= 4.5, 'kolegij s izvrsim prosjekom', '') AS opis
FROM kolegiji
         JOIN ocjene ON kolegiji.id = ocjene.idKolegij
         JOIN smjerovi ON kolegiji.idSmjer = smjerovi.id
         JOIN ustanove ON smjerovi.oibUstanova = ustanove.oib
WHERE ustanove.naziv = 'Tehničko veleučilište u Zagrebu'
GROUP BY kolegiji.naziv, smjerovi.naziv
ORDER BY prosjecna_ocjena DESC;


/*Izraditi popis svih kolegija na Tehničkom veleučilištu u Zagrebu sa prosječnim ocjenama na kolegiju i s nazivom smjera kojem kolegij pripada.
Ovisno o prosjeku ocjena na kolegiju, ispisati poruke ‘kolegij s izvrsnim prosjekom’ ili ‘kolegij s vrlo dobrim prosjekom’ itd.*/


SELECT kolegiji.naziv,
       smjerovi.naziv,
       AVG(ocjena) prosjecna_ocjena,
       CASE
           WHEN AVG(ocjena) >= 4.5 THEN 'kolegij s izvrsnim prosjekom'
           WHEN AVG(ocjena) >= 3.5 THEN 'kolegij s vrlo dobrim prosjekom'
           WHEN AVG(ocjena) >= 2.5 THEN 'kolegij s dobrim prosjekom'
           WHEN AVG(ocjena) >= 1.5 THEN 'kolegij s dovoljnim prosjekom'
           ELSE 'kolegij s većinom neprolaznih ocjena'
           END
FROM kolegiji
         JOIN ocjene ON kolegiji.id = ocjene.idKolegij
         JOIN smjerovi ON kolegiji.idSmjer = smjerovi.id
         JOIN ustanove ON smjerovi.oibUstanova = ustanove.oib
WHERE ustanove.naziv = 'Tehničko veleučilište u Zagrebu'
GROUP BY kolegiji.naziv, smjerovi.naziv
ORDER BY prosjecna_ocjena DESC;


/*Primjer uporabe provjere radi li se o NULL vrijednosti prije konkatenacije. Funkcija konkatenacije vratiti će NULL
  vrijednost ako je makar jedna njena vrijednost jednaka NULL.
  Većinom ćemo htjeti dobti rezultat preostalih stringova koji se mogu konkatenirati. */

SELECT CONCAT('Ivan', ' ', NULL);

SELECT CONCAT('Ivan', ' ', IFNULL(NULL, ''));

SELECT CONCAT('Ivan', ' ', IFNULL('Horvat', ''));



/*******KONTROLA TOKA U POHRANJENIM ZADATCIMA*********/
/*Napisati funkciju koja će dohvatiti trenutni datum s poslužitelja 
i ispisati koji je dan u tjednu.*/

SELECT CURDATE();
SELECT DAY(CURDATE());
SELECT DAYOFWEEK(CURDATE());


DELIMITER //
DROP FUNCTION IF EXISTS danUTjednu //
CREATE FUNCTION danUTjednu() RETURNS VARCHAR(50)
    DETERMINISTIC
BEGIN
    DECLARE vrati VARCHAR(50);
    CASE DAYOFWEEK(CURDATE())
        WHEN 2 THEN SET vrati = 'Danas je ponedjeljak';
        WHEN 3 THEN SET vrati = 'Danas je utorak';
        WHEN 4 THEN SET vrati = 'Danas je srijeda';
        WHEN 5 THEN SET vrati = 'Danas je četvrtak';
        WHEN 6 THEN SET vrati = 'Danas je petak';
        ELSE SET vrati = 'Danas je vikend';
        END CASE;
    RETURN vrati;
END;
//
DELIMITER ;

SELECT danUTjednu();


/*Napisati proceduru koja će ispisati prvih n prirodnih brojeva
u jednoj varijabli. 
Brojevi moraju biti razdvojeni zarezom. 
Zanemarite ako se zarez ispisuje i nakon zadnjeg broja.


*/
DELIMITER $$
DROP PROCEDURE IF EXISTS WhileLoopProc_zarez $$
CREATE PROCEDURE WhileLoopProc_zarez(IN n INT)
BEGIN
    DECLARE var INT DEFAULT NULL;
    DECLARE str VARCHAR(255) DEFAULT NULL;
    SET var = 1;
    SET str = '';
    WHILE var <= n
        DO
            SET str = CONCAT(str, var, ',');
            SET var = var + 1;
        END WHILE;
    SELECT str;
END $$
DELIMITER ;
CALL WhileLoopProc_zarez(8);


/*Nadogradnja na prethodni zadatak.
Obratite pažnju da se zarez NE ispisuje i nakon zadnjeg broja.
*/
DELIMITER $$
DROP PROCEDURE IF EXISTS WhileLoopProc_provjera$$
CREATE PROCEDURE WhileLoopProc_provjera(IN n INT)
BEGIN
    DECLARE var INT DEFAULT NULL;
    DECLARE str VARCHAR(255) DEFAULT NULL;
    SET var = 1;
    SET str = '';
    WHILE var <= n
        DO
            IF var < n THEN
                SET str = CONCAT(str, var, ',');
            ELSEIF var = n THEN
                SET str = CONCAT(str, var);
            END IF;
            SET var = var + 1;
        END WHILE;
    SELECT str;
END $$
DELIMITER ;
CALL WhileLoopProc_provjera(8);


/*Nadogradnja na prethodni zadatak.
Korištenje funkcije CONCAT_WS.
*/
SELECT CONCAT('prvi', 'drugi');
SELECT CONCAT_WS('|', 'prvi', 'drugi');

DELIMITER $$
DROP PROCEDURE IF EXISTS WhileLoopProc$$
CREATE PROCEDURE WhileLoopProc(IN n INT)
BEGIN
    DECLARE var INT DEFAULT NULL;
    DECLARE str VARCHAR(255) DEFAULT NULL;
    SET str = '1';
    SET var = 2;
    WHILE var <= n
        DO
            SET str = CONCAT_WS(',', str, var);
            SET var = var + 1;
        END WHILE;
    SELECT str;
END $$
DELIMITER ;

CALL WhileLoopProc(8);


/*Napisati proceduru koja za zadani odjel broji radnike koji
pripadaju tom odjelu. 
Ako odjel ima više od 10 radnika, procedura mora vratiti -1, 
a ako odjel nema radnika, procedura mora vratiti 0. 
U ostalim slučajevima, procedura vraća stvarni broj radnika. 
Napisati poziv procedure za odjel 100005. 
Napisati poziv procedure za odjel 5.
*/

DELIMITER //
CREATE PROCEDURE odjel_rad(IN zadaniOdjel INT, OUT broj INT)
BEGIN
    SELECT COUNT(*) INTO broj FROM radnik WHERE sifOdjel = zadaniOdjel;
    IF broj > 10 THEN
        SET broj = -1;
    END IF;
END;
//
DELIMITER ;

CALL odjel_rad(100005, @a);
SELECT @a;

CALL odjel_rad(5, @a);
SELECT @a;


/*Napisati funkciju za unos novog odjela u tablicu odjel
(atributi sifra i naziv odjela). 
Funkcija treba provjeriti postoji li već odjel sa zadanim imenom. 
Ako postoji, završiti s radom (vrati 0). 
Ako ne postoji, pridijeliti mu šifru i unijeti u tablicu (vrati 1). 
(Primijetiti da na šifri odjela ne postoji autoincrement.)
*/
DELIMITER //
DROP FUNCTION IF EXISTS unesiOdjel //
CREATE FUNCTION unesiOdjel(noviOdjel VARCHAR(50)) RETURNS INT
    DETERMINISTIC
BEGIN
    DECLARE broj, vrati, zadnji INT DEFAULT NULL;
    SELECT COUNT(*)
    INTO broj
    FROM odjel
    WHERE nazivOdjel = noviOdjel;
    IF broj = 0 THEN
        SELECT MAX(sifOdjel) INTO zadnji FROM odjel;
        INSERT INTO odjel (sifOdjel, nazivOdjel)
        VALUES ((zadnji + 1), noviOdjel);
        SET vrati = 1;
    ELSE
        SET vrati = 0;
    END IF;
    RETURN vrati;
END;
//
DELIMITER ;
SELECT unesiOdjel('Odjel za lakiranje');
SELECT *
FROM odjel;
SELECT unesiOdjel('Bojanje');
SELECT *
FROM odjel;








