/* 1. U bazi STUDENTI, zaključati tablicu OCJENE zbog ČITANJA, a tablicu KOLEGIJI
zbog pisanja.
U drugoj sesiji pokusajte izracunati prosjek ocjena za sve kolegije (idkolegija,
prosjek).
U trećoj sesiji izračunajte to isto ali dodajte i naziv kolegija (idkolegija,
naziv kolegija,prosjek).
Otključajte tablice i pogledajte rezultate u ostalim sesijama.
*/

-- U PRVOJ SESIJI
LOCK TABLES ocjene READ, kolegiji WRITE;

-- nakon pokretanja 2. i 3. sesije
UNLOCK TABLES;
-- U DRUGOJ SESIJI
SELECT idKolegij, AVG(ocjena) AS prosjek
FROM ocjene
GROUP BY idKolegij;
-- U TREĆOJ SESIJI
SELECT o.idKolegij, k.naziv, AVG(o.ocjena) AS prosjek
FROM ocjene o
         JOIN kolegiji k ON o.idKolegij = k.id
GROUP BY o.idKolegij, k.naziv;


/* 2. Napisati transakciju koja će zaključati n-torke u tablici KLIJENT koji po
mjestu registracije pripadaju Zagrebu (10000), te po nazivu dana u tjednu vraća
broj prijavljenih klijenata.
Transakciju napisati na način da druge sesije/transakcije ne mogu mijenjati
podatke o tim klijentima, ali ih mogu čitati.
U drugoj sesiji:
a) pokušati pročitati podatke o klijentima za Zagreb (po registraciji)
b) pokušati promijeniti podatke o tim klijentimana način da se prezime postavi na
velika slova.
 */

SELECT *
FROM klijent
WHERE sifKlijent = 1137;


BEGIN WORK;
SELECT DAYNAME(datUnosKlijent), COUNT(*)
FROM klijent k
WHERE pbrReg = 10000
GROUP BY DAYNAME(datUnosKlijent) LOCK IN SHARE MODE;
COMMIT;


/* 4. Napisati transakciju koja će zaključati n-torke u tablici STUDENTI koje
pripadaju smjeru 'računalstvo', te vratiti broj studenta na tom smjeru.
Transakciju napisati na način da druge sesije/transakcije ne mogu niti mijenjati
ni čitati podatke o tim studentima.
U drugoj sesiji:
a) pokušati pročitati podatke o tim studentima
b) pokušati promijeniti podatke o tim studentima
na velika slova.
na način da se prezime postavi
/* Prva sesija */
BEGIN WORK;
SELECT COUNT(*) AS BR_STUDENATA
FROM studenti
WHERE idSmjer = 1 FOR UPDATE;
COMMIT;
/* Druga sesija */
SELECT *
FROM studenti
WHERE idSmjer
          = 1;
UPDATE studenti
SET ime = UPPER(ime)
WHERE idSmjer = 1;