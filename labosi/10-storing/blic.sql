/*U sklopu baze podataka, izraditi tablicu 'TABLICE' koja će opisivati podatke o tablicama: id tablice (PK), naziv_tablice, schema, engine, status tablice, timestamp_kreiranja.

Isto tako izraditi i child tablicu  'ATRIBUTI' koja  opisuje atribute, ona ima svoj id (PK), naziv_atributa, tip_atrib, id_tbl kojoj pripada (FK).
Odabrati / promijeniti mehanizam pohrane podataka koji će omogućiti:

a)  Zaključavanje podataka na razini retka (napisati primjer zaključavanja zbog čitanja za sve n-torke koje pripadaju shemi STUDENTI, i imaju engine  MyISAM ili InnoDB i tipa su INTEGER.  Upit sadrži sve atribute iz tablice "ATRIBUTI" te iz tablice "TABLICE" kao i naziv tablice).

b) Postavljanje stranog ključa naziva 'str_kljuc_tbl' na atribut id_tbl koji referencira na primarni ključ  'id' u tablici 'TABLICE'.

c) Što kraće vrijeme pretrage podataka, podršku za full text indeks. Ako je potrebno, obaviti potrebne predradnje.

d) Prikazati naziv baze, tablice i mehanizam pohrane za tablice 'TABLICE' i 'ATRIBUTI'.*/


CREATE TABLE TABLICE
(
    id                  INT PRIMARY KEY,
    naziv_tablice       VARCHAR(50),
    schema_tablice      VARCHAR(100),
    engine_tablice      VARCHAR(50),
    status              VARCHAR(50),
    timestamp_kreiranja TIMESTAMP
);

CREATE TABLE ATRIBUTI
(
    id             INT PRIMARY KEY,
    naziv_atributa VARCHAR(50),
    tip_atrib      VARCHAR(50),
    id_tbl         INT,
    FOREIGN KEY (id_tbl) REFERENCES TABLICE (id)
);

# a
ALTER TABLE TABLICE
    ENGINE InnoDB;

SELECT T.*, A.*, T.naziv_tablice
FROM TABLICE T
         JOIN ATRIBUTI A ON T.id = A.id_tbl
WHERE schema_tablice = 'STUDENTI'
  AND engine_tablice IN ('MyISAM', 'InnoDB')
  AND tip_atrib = 'INTEGER' LOCK IN SHARE MODE;

# b
ALTER TABLE ATRIBUTI
    ADD CONSTRAINT str_klj_tabl FOREIGN KEY (id_tbl) REFERENCES TABLICE (id);

# c
ALTER TABLE ATRIBUTI
    DROP FOREIGN KEY str_klj_tabl;

ALTER TABLE ATRIBUTI
    DROP FOREIGN KEY ATRIBUTI_ibfk_1;

ALTER TABLE ATRIBUTI
    ENGINE MyISAM;

SHOW TABLE STATUS WHERE name = 'ATRIBUTI';

# d
SELECT TABLE_SCHEMA, TABLE_NAME, ENGINE
FROM information_schema.TABLES
WHERE TABLE_NAME IN ('TABLICE', 'ATRIBUTI');


