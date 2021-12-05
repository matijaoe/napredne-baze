/* 1. U bazi autoradionica: Napisati transakciju koja će sve rezervacije koje
imaju satServis =1 dodijeliti radionici "R99". Nakon toga je potrebno radionici "R99"
povećati broj radnika za 1.
Potrebno je potvrditi da su se promjene u bazi dogodile (COMMIT).
Napisati upit(e) koji je potrebno pozvati prije i nakon transakcije kako bi
se provjerila uspješnost napisanog koda */


SELECT *
FROM rezervacija
WHERE satServis = 1;
SELECT *
FROM radionica r
WHERE r.oznRadionica = 'R99';

SET AUTOCOMMIT = 0;
START TRANSACTION;
UPDATE rezervacija
SET oznRadionica = 'R99'
WHERE satServis = 1;
UPDATE radionica r
SET r.kapacitetRadnika = r.kapacitetRadnika + 1
WHERE r.oznRadionica = 'R99';
COMMIT;
SET AUTOCOMMIT = 1;

SELECT *
FROM rezervacija
WHERE satServis = 1;

SELECT *
FROM radionica r
WHERE r.oznRadionica = 'R99';


/*
/* 2. U bazi autoradionica: Napisati transakciju koja će svim rezervacijama sa
šifrom kvara 33 a nisu predviđene za petak, umanjiti sat servisa za 1 (ako već nisu
1). Nakon toga će sve druge rezervacije za petak čija je šifra kvara različita od 33
obrisati.
Potrebno je potvrditi da se prva promjena dogodila a druga promjena (brisanje)
nije dogodila.
Napisati upit(e) koji je potrebno pozvati prije i nakon transakcije kako bi
se provjerila uspješnost napisanog koda.
*/
SELECT *
FROM rezervacija
WHERE sifKvar = 33
  AND datVrstaDan <> 'PE'
  AND satServis > 1;

SELECT *
FROM rezervacija
WHERE datVrstaDan = 'PE'
  AND sifKvar <> 33;

--
SET AUTOCOMMIT = 0;
BEGIN;
UPDATE rezervacija
SET satServis = satServis - 1
WHERE sifKvar = 33
  AND datVrstaDan <> 'PE'
  AND satServis > 1;
SAVEPOINT tocka;
DELETE
FROM rezervacija
WHERE datVrstaDan = 'PE'
  AND sifKvar <> 33;
ROLLBACK TO SAVEPOINT tocka;
COMMIT;
SET AUTOCOMMIT = 1;
--

SELECT *
FROM rezervacija
WHERE sifKvar = 33
  AND datVrstaDan <> 'PE'
  AND satServis > 1;

SELECT *
FROM rezervacija
WHERE datVrstaDan = 'PE'
  AND sifKvar <> 33;

/* 3. U bazi autoradionica: Napisati transakciju koja će svim radnicima s plaćom
manjom od 1000 povećati osnovicu za 200 a radnicima s plaćom većom od 5000 osnovicu
smanjiti za 100.
Potrebno je potvrditi da se prva promjena dogodila a druga promjena (smanjenje) nije
dogodila.
Napisati upit(e) koji je potrebno pozvati prije i nakon transakcije kako bi se
provjerila uspješnost napisanog koda. */
SELECT *
FROM radnik
WHERE KoefPlaca * IznosOsnovice < 1000;
SELECT *
FROM radnik
WHERE KoefPlaca * IznosOsnovice > 5000;

SET AUTOCOMMIT = 0;
BEGIN;
UPDATE radnik
SET IznosOsnovice = IznosOsnovice + 200
WHERE KoefPlaca * IznosOsnovice < 1000;
SAVEPOINT tocka;
UPDATE radnik
SET IznosOsnovice = IznosOsnovice - 100
WHERE KoefPlaca * IznosOsnovice > 5000;
ROLLBACK TO SAVEPOINT tocka;
COMMIT;
SET AUTOCOMMIT = 1;

SELECT *
FROM radnik
WHERE KoefPlaca * IznosOsnovice < 1000;
SELECT *
FROM radnik
WHERE KoefPlaca * IznosOsnovice > 5000;


/* 4. U bazi studenti: Napisati transakciju koja će sve ispite iz kolegija 20
povećati za jednu ocjenu (osim ocjene 1 i 5) ako pripadaju smjeru čiji je ID 10. Isto
tako smanjiti sve ocjene za 1 ako iz kolegija 30 i smjera 15 (osim ocjena 1 i 2).
Potrebno je potvrditi da se promjene u bazi nisu dogodile. */
SELECT *
FROM ocjene
         JOIN kolegiji k ON k.id = ocjene.idKolegij
WHERE idKolegij = 20
  AND ocjena NOT IN (1, 5)
  AND idSmjer = 10;
SELECT *
FROM ocjene
         JOIN kolegiji k ON k.id = ocjene.idKolegij
WHERE idKolegij = 30
  AND ocjena NOT IN (1, 2)
  AND idSmjer = 15;

--
SET AUTOCOMMIT = 0;
BEGIN;
UPDATE ocjene
    JOIN kolegiji k ON k.id = ocjene.idKolegij
SET ocjena = ocjena + 1
WHERE idKolegij = 20
  AND ocjena NOT IN (1, 5)
  AND idSmjer = 10;
SAVEPOINT tocka;

UPDATE ocjene
    JOIN kolegiji k ON k.id = ocjene.idKolegij
SET ocjena = ocjena - 1
WHERE idKolegij = 30
  AND ocjena NOT IN (1, 2)
  AND idSmjer = 15;

ROLLBACK TO SAVEPOINT tocka;
COMMIT;
SET AUTOCOMMIT = 1;
--


/* 5. U bazi autoradionica: Napisati transakciju koja će radniku koji je napravio
najviše naloga
povećati koeficijent plaće za 0.5 a radniku koji je napravio najmanje smanjiti
koeficijent plaće za 0.2.
Potrebno je potvrditi da se prva promjena dogodila a druga promjena (smanjenje) nije
dogodila. Ako je više
od jednog radnika, drugi kriterij je ukupna suma sati.
Ispisati šifre radnika, broj naloga, sumu sati i koef plaće*/
SELECT sifRadnik
FROM nalog
GROUP BY sifRadnik
ORDER BY COUNT(*) DESC, SUM(OstvareniSatiRada) DESC
LIMIT 1;

SET AUTOCOMMIT = 0;
BEGIN;
UPDATE radnik
SET KoefPlaca = KoefPlaca + 0.5
WHERE sifRadnik = (SELECT sifRadnik
                   FROM nalog
                   GROUP BY sifRadnik
                   ORDER BY COUNT(*) DESC, SUM(OstvareniSatiRada) DESC
                   LIMIT 1);
SAVEPOINT tocka;
UPDATE radnik
SET KoefPlaca = KoefPlaca - 0.2
WHERE sifRadnik = (SELECT sifRadnik
                   FROM nalog
                   GROUP BY sifRadnik
                   ORDER BY COUNT(*), SUM(OstvareniSatiRada)
                   LIMIT 1);
ROLLBACK TO SAVEPOINT tocka;
COMMIT;
SET AUTOCOMMIT = 1;

SELECT sifRadnik, COUNT(*) br_naloga, SUM(OstvareniSatiRada) suma_sati, KoefPlaca
FROM nalog
         NATURAL JOIN radnik
GROUP BY sifRadnik, koefPlaca
ORDER BY 2 DESC, 3 DESC;