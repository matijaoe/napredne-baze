/* 1. U sklopu baze podataka, izraditi tablicu 'muzeji' koja će opisivati podatke o muzejima: id, naziv muzeja, id mjesta
(lokacije muzeja), id vrste muzeja, izložbena površina, datum otvaranja.
Odabrati / promijeniti mehanizam pohrane podataka koji će omogućiti:
a) Zaključavanje podataka u tablici na razini retka (napisati primjer zaključavanja zbog pisanja za sve muzeje
otvorene poslije 2001 godine i da im je izložbena površina od 1000 do 2500 m2, uključno)
b) Zaključavanje podataka u tablici na razini tablice, ali ne i na razini retka (napisati primjer zaključavanja tablice
zbog čitanja, otključati zaključano)
c) Postavljanje stranog ključa naziva str_kljuc na atribut id_mjesto koji referencira na primarni ključ postbr u
tablici mjesta.
d) Što kraće vrijeme pretrage podataka, podršku za full text indeks. Ako je potrebno, obaviti potrebne predradnje.
e) Prikazati naziv baze, tablice i mehanizam pohrane za tablicu muzeji.*/


USE studenti;
CREATE TABLE muzeji
(
    id            INT,
    naziv         VARCHAR(100),
    id_vrsta      INT,
    id_mjesto     INT,
    izl_povrsina  INT,
    dat_otvaranja DATE
);


-- a

ALTER TABLE muzeji
    ENGINE ARCHIVE;

SELECT *
FROM muzeji
WHERE YEAR(dat_otvaranja) > 2001
  AND izl_povrsina BETWEEN 1000 AND 2500 FOR
UPDATE;

-- b
ALTER TABLE muzeji
    ENGINE MYISAM;


LOCK TABLES muzeji READ;
-- SHOW VARIABLES WHERE Variable_Name LIKE '%dir';


-- c
ALTER TABLE muzeji
    ENGINE INNODB;

ALTER TABLE studenti.muzeji
    ADD CONSTRAINT str_kljuc FOREIGN KEY (id_mjesto) REFERENCES studenti.mjesta (postbr);


-- d

ALTER TABLE muzeji
    ENGINE MYISAM;

ALTER TABLE muzeji
    DROP FOREIGN KEY str_kljuc;


SHOW TABLE STATUS WHERE name = 'muzeji';

-- e

SELECT TABLE_SCHEMA, TABLE_NAME, ENGINE
FROM information_schema.TABLES;


/* 2. U bazi radionica, izraditi tablicu 'odjel_radnik' koja će opisivati podatke o trenutnoj i prošloj pripadnosti radnika
odjelu: sifRadnik, sifOdjel, datum_od, datum_do, ts_azuriranja (timestamp).
Odabrati / promijeniti mehanizam pohrane podataka koji će omogućiti:
a) Zaključavanje podataka u tablici na razini retka (napisati primjer zaključavanja zbog čitanja za sve n-torke koje
imaju datum_DO prazan ili je prisutnost radnika u nekom odjelu bila manja od 30 dana.
b) Zaključavanje podataka u tablici na razini tablice, ali ne i na razini retka (napisati primjer zaključavanja tablice
zbog pisanja, otključati zaključano).
c) Postavljanje stranog ključa naziva str_klj_rad na atribut sifRadnik koji referencira na primarni ključ sifRadnik u
tablici radnik i stranog ključa naziva str_klj_odj na atribut sifOdjel koji referencira na primarni ključ sifOdjel u
tablici odjel.
d) Prikazati naziv baze, tablice i engine za tablice: radnik, odjel, odjel_radnik.*/

USE autoradionica;

CREATE TABLE odjel_radnik
(
    sifRadnik     INT,
    sifOdjel      INT,
    datum_od      DATE,
    datum_do      DATE,
    ts_azuriranja TIMESTAMP
);

# a
ALTER TABLE odjel_radnik
    ENGINE InnoDB;

SELECT *
FROM odjel_radnik
WHERE datum_do IS NULL
   OR (datum_od IS NOT NULL AND DATEDIFF(datum_do, datum_od) < 30) LOCK IN SHARE MODE;

# b
ALTER TABLE odjel_radnik
    ENGINE MYISAM;

LOCK TABLES odjel_radnik WRITE;
UNLOCK TABLES;

# c
ALTER TABLE odjel_radnik
    ENGINE InnoDB;

ALTER TABLE odjel_radnik
    ADD CONSTRAINT str_klj_rad FOREIGN KEY (sifRadnik) REFERENCES autoradionica.radnik (sifRadnik);

ALTER TABLE odjel_radnik
    ADD CONSTRAINT str_klj_odj FOREIGN KEY (sifOdjel) REFERENCES autoradionica.odjel (sifOdjel);

# d
SELECT TABLE_SCHEMA, TABLE_NAME, ENGINE
FROM information_schema.TABLES
WHERE TABLE_NAME IN ('radnik', 'odjel', 'odjel_radnik');

SHOW TABLE STATUS WHERE name = 'odjel_radnik';


/* 3. U sklopu baze radionica, izraditi tablicu 'doprinosi_po_zup' koja po svim županijama prikazuje broj radnika i
doprinos od radnika (računati ga kao 25% od plaće svih radnika u toj županiji). Nova tablica mora sadržavati zapise o
svim županijama, bez obzira je li u njoj postoji zapis o mjestu ili zaposlenom radniku.
Odabrati / promijeniti mehanizam pohrane podataka koji će omogućiti:
a) Zaključavanje podataka u bazi podataka na razini retka. Napisati primjer zaključavanja zbog čitanja za sve n-
torke koje imaju manje od 10 radnika ili doprinos manji od 1000kn. Prikazati novi mehanizam pohrane
podataka za tu tablicu. Navesti koje se vrste datoteka stvaraju na disku (pomoću SHOW VARIABLES WHERE
Variable_Name LIKE "%dir").
b) Zaključavanje podataka u bazi podataka na razini tablice, ali ne i na razini retka (napisati primjer zaključavanja
zbog pisanja, nakon toga ih otključati). Navesti koje se vrste datoteka stvaraju na disku.
c) Što kraće vrijeme pretrage podataka, podršku za full text index. Navesti koje se vrste datoteka stvaraju na
disku.*/

CREATE TABLE doprinos_po_zup AS
SELECT z.nazivZupanija,
       COUNT(r.sifRadnik)                                  br_radnika,
       ROUND(SUM(r.KoefPlaca * r.IznosOsnovice * 0.25), 0) doprinos
FROM radnik r
         JOIN mjesto m ON r.pbrStan = m.pbrMjesto
         RIGHT JOIN zupanija z ON m.sifZupanija = z.sifZupanija
GROUP BY z.nazivZupanija
ORDER BY 2 DESC;

# a
SELECT *
FROM doprinos_po_zup
WHERE br_radnika < 10
   OR doprinos < 1000 LOCK IN SHARE MODE;

SHOW VARIABLES WHERE
    Variable_Name LIKE '%dir';

/* Stvorene datoteke:
doprinosi_po_zup.sdi
doprinosi_po_zup.ARZ */

# b
ALTER TABLE doprinos_po_zup
    ENGINE myisam;

/* Stvorene datoteke:
doprinosi_po_zup.sdi */

LOCK TABLES doprinos_po_zup WRITE;
UNLOCK TABLES;

# c
ALTER TABLE doprinosi_po_zup ENGINE MYISAM;
/* Stvorene datoteke:
doprinosi_po_zup.sdi
doprinosi_po_zup.MYI
doprinosi_po_zup.MYD */
SHOW TABLE STATUS WHERE NAME = 'doprinosi_po_zup';