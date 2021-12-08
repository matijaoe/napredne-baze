/*  U bazi STUDENTI:
Napisati transakciju koja će svim studentima iza prezimena dodati  oznaku '-  negativni_3_ispod '
ako su imali više od 3 negativne ocjene na ispitima i bili ispod sveukupnog prosjeka.
Studentima koji su imali više od 5 položenih ispita i  prosjek položenih ispita veći od 3.5
dodati iza prezimena oznaku '- pozitivni_5_AVG_3_5 ' .
Potrebno je potvrditi obje promjene.*/

SET AUTOCOMMIT = 0;
BEGIN;

SELECT AVG(ocjena)
INTO @uk_prosjek
FROM ocjene;

UPDATE studenti
SET prezime = CONCAT(prezime, '- negativni_3_ispod')
WHERE jmbag IN (
    SELECT jmbagStudent
    FROM ocjene
    WHERE ocjena = 1
    GROUP BY jmbagStudent
    HAVING COUNT(*) > 3
       AND AVG(ocjena) < @uk_prosjek
);

UPDATE studenti
SET prezime = CONCAT(prezime, '- pozitivni_5_AVG_3_5')
WHERE jmbag IN (
    SELECT jmbagStudent
    FROM ocjene
    WHERE ocjena > 1
    GROUP BY jmbagStudent
    HAVING COUNT(*) > 5
       AND AVG(ocjena) > 3.5
);

COMMIT;
SET AUTOCOMMIT = 1;


SELECT *
FROM studenti
WHERE prezime LIKE '%negativni%';

SELECT *
FROM studenti
WHERE prezime LIKE '%pozitivni%';