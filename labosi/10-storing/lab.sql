/* 1. U sklopu baze podataka, izraditi tablicu 'PARKOVI' koja će opisivati podatke o parkovima: 
id parka (PK), naziv parka, id mjesta (lokacije parka), id vrste parka, površina, datum izgradnje. 
Isto tako formirati i parent tablicu za parkove 'VRSTE_PARKOVA' koja ima svoj id_vrste (PK) i naziv_vrste.
Odabrati / promijeniti mehanizam pohrane podataka koji će omogućiti:
a)            Zaključavanje podataka na razini retka (napisati primjer zaključavanja zbog pisanja za sve 
parkove otvorene u drugom ili trećem kvartalu bilo koje godine i da su po površini veći od 3000 m2,
   upit sadrži sve atribute iz tablice 'PARKOVI' i naziv vrste parka iz tablice 'VRSTE_PARKOVA').
b)           Postavljanje stranog ključa naziva 'str_kljuc_mj' na atribut id_mjesto koji referencira na primarni ključ
                'postbr' u tablici MJESTA, kao i stranog ključa naziva 'str_kljuc_vr' na atribut 'id_vrsta' koji referencira
               na primarni ključ 'id_vrste' u tablici 'VRSTE_PARKOVA'.
c)            Što kraće vrijeme pretrage podataka, podršku za full text indeks.  Ako je potrebno, obaviti potrebne predradnje.
d)           Prikazati naziv baze, tablice i mehanizam pohrane za tablice 'PARKOVI' i 'VRSTE_PARKOVA'.*/

USE studenti;

CREATE TABLE parkovi
(
    id            int PRIMARY KEY,
    naziv         varchar(100),
    id_mjesta     int,
    id_vrste      int,
    povrsina_m2   int,
    dat_izgradnje date
);

CREATE TABLE vrste_parkova
(
    id_vrste    int PRIMARY KEY,
    naziv_vrste varchar(100)
);

-- a

SELECT *
FROM parkovi
         JOIN vrste_parkova vp ON parkovi.id_mjesta = vp.id_vrste
WHERE QUARTER(dat_izgradnje) IN (2, 3)
  AND povrsina_m2 > 3000 FOR
UPDATE;


-- b
ALTER TABLE studenti.parkovi
    ADD CONSTRAINT str_kljuc_mj FOREIGN KEY (id_mjesta) REFERENCES studenti.mjesta (postbr);

ALTER TABLE studenti.parkovi
    ADD CONSTRAINT str_kljuc_vr FOREIGN KEY (id_vrste) REFERENCES studenti.vrste_parkova (id_vrste);

-- c
ALTER TABLE parkovi
    ENGINE MYISAM;

ALTER TABLE parkovi
    DROP FOREIGN KEY str_kljuc_mj;
ALTER TABLE parkovi
    DROP FOREIGN KEY str_kljuc_vr;

SELECT table_schema, table_name, ENGINE
FROM information_schema.tables
WHERE table_schema = 'studenti'
  AND table_name IN ('parkovi', 'vrste_parkova');


/* 2. U sklopu baze radionica, izraditi tablicu 'KVAROVI_PO_GOD' koja po godinama i nazivima kvarova prikazuje
broj naloga i prosječne ostvarene sate. Odabrati samo one retke koji imaju više od jednog naloga.
Sortirati po broju kvarova padajući i godinama rastući.
Odabrati / promijeniti mehanizam pohrane podataka koji će omogućiti:
a) Zaključavanje podataka u bazi podataka na razini retka. Napisati primjer zaključavanja zbog čitanja za sve n-torke
   koje imaju između 10 i 20 naloga ili prosjek sati između 6 i 7.
    Prikazati novi mehanizam pohrane podataka za tu tablicu. Navesti koje se vrste datoteka stvaraju na disku
   (pomoću SHOW VARIABLES WHERE Variable_Name LIKE "%dir").
b) Zaključavanje podataka u bazi podataka na razini tablice, ali ne i na razini retka
   (napisati primjer zaključavanja zbog pisanja, nakon toga ih otključati). Navesti koje se vrste datoteka stvaraju na disku.
c) Nema ograničenja na veličinu baze. Navesti koje se vrste datoteka stvaraju na disku. */

USE autoradionica;

CREATE TABLE kvarovi_po_god AS
SELECT YEAR(datPrimitkaNalog) AS god, sifKvar, COUNT(*) br_nal, AVG(OstvareniSatiRada) prosjek_sati
FROM nalog
GROUP BY YEAR(datPrimitkaNalog), sifKvar
HAVING br_nal > 1
ORDER BY 2 DESC, 1;

SELECT *
FROM kvarovi_po_god;

-- a
SELECT *
FROM kvarovi_po_god
WHERE br_nal BETWEEN 10 AND 20
   OR prosjek_sati BETWEEN 6 AND 7 LOCK IN SHARE MODE;



SHOW VARIABLES WHERE Variable_Name LIKE '%dir';


-- b) -----------------------------------------------------------
ALTER TABLE kvarovi_po_god
    ENGINE MyISAM;

/* Stvorene datoteke:
kvarovi_po_god.sdi
kvarovi_po_god.MYI
kvarovi_po_god.MYD */

LOCK TABLES kvarovi_po_god WRITE;

UNLOCK TABLES;

-- c) -----------------------------------------------------------
ALTER TABLE kvarovi_po_god
    ENGINE ARCHIVE;

/* Stvorene datoteke:
kvarovi_po_god.sdi
kvarovi_po_god.ARZ*/

SHOW TABLE STATUS WHERE NAME = 'kvarovi_po_god';

