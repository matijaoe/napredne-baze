/* 1. U bazi autoradionica:
Napisati transakciju koja će svim onim radnicima koji su po nalozima radili petkom i imali veći prosjek ostvarenih sati rada od
svih koji su radili petkom, povećati osnovicu za 30 kn, a radnicima koji po nalozima nisu radili petkom i pri tome imali manji
prosjek od onih koji isto nisu radili petkom, osnovicu smanjiti za 10 kn.
Potrebno je potvrditi da se prva promjena dogodila a druga promjena (smanjenje) nije dogodila./*
 */

SET AUTOCOMMIT = 0;
BEGIN;

SELECT AVG(OstvareniSatiRada)
INTO @v_AVG_Fr
FROM nalog
WHERE DAYNAME(datPrimitkaNalog) = 'Friday';

SELECT AVG(OstvareniSatiRada)
INTO @v_AVG_non_Fr
FROM nalog
WHERE DAYNAME(datPrimitkaNalog) <> 'Friday';

UPDATE radnik
SET IznosOsnovice = IznosOsnovice + 30
WHERE sifRadnik IN
      (SELECT sifRadnik
       FROM nalog
       WHERE DAYNAME(datPrimitkaNalog) = 'Friday'
       GROUP BY sifRadnik
       HAVING AVG(OstvareniSatiRada) >= @v_AVG_Fr);
SAVEPOINT tocka;

UPDATE radnik
SET IznosOsnovice = IznosOsnovice - 10
WHERE sifRadnik IN
      (SELECT sifRadnik
       FROM nalog
       WHERE DAYNAME(datPrimitkaNalog) <> 'Friday'
       GROUP BY sifRadnik
       HAVING AVG(OstvareniSatiRada) < @v_AVG_non_Fr);

ROLLBACK TO SAVEPOINT tocka;
COMMIT;
SET AUTOCOMMIT = 1;


/* 2. U bazi autoradionica:
Napisati transakciju koja će svim klijentima iza prezimena dodati oznaku '- VIP' i
   ime postaviti na velika slova ako su do sada
(po nalozima) imali više od 6 popravaka (prioriteta 1 ili 2).
Ukoliko su imali manje od 3 popravka (prioriteta 1 ili 2) dobivaju
oznaku '-REGULAR'. Potrebno je potvrditi da se prva promjena dogodila a druga promjena nije dogodila.
Napisati upit(e) koji(e) je potrebno pozvati prije i nakon transakcije kako bi se provjerila uspješnost
napisanog koda.*/
SELECT sifKlijent, prezimeKlijent
FROM klijent k
         NATURAL JOIN nalog
WHERE prioritetNalog IN (1, 2)
GROUP BY sifKlijent, prezimeKlijent
HAVING COUNT(*) > 6;

SELECT sifKlijent, prezimeKlijent
FROM klijent k
         NATURAL JOIN nalog
WHERE prioritetNalog IN (1, 2)
GROUP BY sifKlijent, prezimeKlijent
HAVING COUNT(*) < 3;


SET AUTOCOMMIT = 0;
BEGIN;

UPDATE klijent
SET prezimeKlijent = CONCAT(UPPER(prezimeKlijent), ' - VIP')
WHERE sifKlijent IN (
    SELECT sifKlijent
    FROM nalog
    WHERE prioritetNalog IN (1, 2)
    GROUP BY sifKlijent
    HAVING COUNT(*) > 6
);
SAVEPOINT tocka;

UPDATE klijent
SET prezimeKlijent = CONCAT(prezimeKlijent, ' - REGULAR  ')
WHERE sifKlijent IN (
    SELECT sifKlijent
    FROM nalog
    WHERE prioritetNalog IN (1, 2)
    GROUP BY sifKlijent
    HAVING COUNT(*) < 3
);
ROLLBACK TO SAVEPOINT tocka;
COMMIT;
SET AUTOCOMMIT = 1;


/* 4. U bazi autoradionica:
Napisati transakciju koja će svim klijentima iza prezimena dodati oznaku '- VIP' i ime postaviti na velika slova
ako su do sada (po nalozima) imali više od 100 sati rada.
Ukoliko su imali manje ili jednako 100 sati rada dobivaju samo oznaku '-REGULAR' iza prezimena.
Potrebno je potvrditi obje promjene.*/
SELECT *
FROM klijent;


SET AUTOCOMMIT = 0;
BEGIN;
UPDATE klijent
SET prezimeKlijent = CONCAT(UPPER(prezimeKlijent), '- VIP')
WHERE sifKlijent IN (SELECT sifKlijent FROM nalog GROUP BY sifKlijent HAVING SUM(OstvareniSatiRada) > 100);

SAVEPOINT tocka;
UPDATE klijent
SET prezimeKlijent = CONCAT(prezimeKlijent, '- REGULAR')
WHERE sifKlijent IN (SELECT sifKlijent FROM nalog GROUP BY sifKlijent HAVING SUM(OstvareniSatiRada) <= 100);
ROLLBACK TO SAVEPOINT tocka;
COMMIT;
SET AUTOCOMMIT = 1;


/* 8. U bazi studenti:
Napisati transakciju koja će svim kolegijima iza naziva kolegija dodati oznaku '- AVG > 3.5' ako su imali prosjek veći od 3.5 i
više od 1 položenog ispita.
Ukoliko je prosjek manji ili jednak 3.5 i imaju više od 1 položenog ispita dobivaju oznaku '- AVG <= 3.5'
Potrebno je potvrditi samo prvu promjenu.*/
SET AUTOCOMMIT = 0;
BEGIN;
UPDATE kolegiji
SET kolegiji.naziv = CONCAT(kolegiji.naziv, '-AVG>3.5')
WHERE kolegiji.id IN
      (SELECT idKolegij
       FROM ocjene
       GROUP BY idKolegij
       HAVING AVG(ocjena) > 3.5
          AND COUNT(*) > 1);
SAVEPOINT tocka;
UPDATE kolegiji
SET kolegiji.naziv = CONCAT(kolegiji.naziv, '-AVG <=3.5')
WHERE kolegiji.id IN
      (SELECT idKolegij
       FROM ocjene
       GROUP BY idKolegij
       HAVING AVG(ocjena) <= 3.5
          AND COUNT(*) > 1);
ROLLBACK TO SAVEPOINT tocka;
COMMIT;
SET AUTOCOMMIT = 1;

SELECT *
FROM kolegiji;


