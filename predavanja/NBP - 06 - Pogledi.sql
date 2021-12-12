/* Izraditi pogled koji će sadržavati podatke o imenima, prezimenima i plaćama svih radnika. */
CREATE VIEW zaposlenik AS
SELECT `imeRadnik`, `prezimeRadnik`, (`KoefPlaca` * `IznosOsnovice`) AS placa
FROM radnik
ORDER BY placa;


/* Ispis iz pogleda */
SELECT *
FROM zaposlenik;
SELECT *
FROM zaposlenik
WHERE prezimeRadnik LIKE 'M%'
ORDER BY placa DESC;


/* Izrada popisa tablica i pogleda u bazi podataka.*/
SHOW TABLES;
SHOW FULL TABLES;



/* Izraditi pogled koji ne sadržti podatke iz baze već samo daje današnji datum u formatu dd.mm.gggg. */
CREATE VIEW datum AS
SELECT DATE_FORMAT(CURDATE(), '%d.%m.%Y.');
/* ispis iz pogleda */
SELECT *
FROM datum;


/*Pogled iz pogleda - potrebno je izraditi pogled koji će sadržavati podatke o imenima, prezimenima i plaćama svih radnika. Iz tog pogleda, potrebno je izraditi novi koji će vraćati samo one radnike čija je plaća veća od 6000, pri čemu je iznos plaće potrebno u ispisu zaokružiti na dvije decimale. */
DROP VIEW IF EXISTS zaposlenik;
CREATE VIEW zaposlenik AS
SELECT `imeRadnik`,
       `prezimeRadnik`,
       (`KoefPlaca` * `IznosOsnovice`) AS placa
FROM radnik
ORDER BY placa;

CREATE VIEW visoko_placeni AS
SELECT imeRadnik, prezimeRadnik, ROUND(placa, 2)
FROM zaposlenik
WHERE placa > 6000;

SELECT *
FROM zaposlenik;
SELECT *
FROM visoko_placeni;
SELECT *
FROM visoko_placeni
ORDER BY prezimeRadnik;


/* Napisati pogled koji će ispisivati broj radnika po županijama. Želimo ispis pripremiti samo za one županije koje imaju ispod 10 radnika. */
DROP VIEW IF EXISTS radnicke_zupanije;

CREATE VIEW radnicke_zupanije AS
SELECT nazivZupanija,
       COUNT(radnik.sifRadnik) AS br /* nije dobro COUNT(*) jer se u rezultatu neće vidjeti zapisi koji su NULL */
FROM zupanija
         LEFT JOIN mjesto ON zupanija.sifZupanija = mjesto.sifZupanija
         LEFT JOIN radnik ON mjesto.pbrMjesto = radnik.pbrStan
GROUP BY nazivZupanija
HAVING br < 10
ORDER BY br ASC;

SELECT *
FROM radnicke_zupanije;
SELECT *
FROM radnik
WHERE pbrStan = 42250;



/* Izraditi pogled koji će ispisivati samo one nastavnike s ulogom profesora koji nisu evidentirali niti jednu neprolaznu ocjenu. */
CREATE VIEW prof_pozit AS
SELECT *
FROM nastavnici
         JOIN izvrsitelji ON jmbg = jmbgNastavnik
         JOIN `ulogaizvrsitelja` ON `idUlogaIzvrsitelja` = `ulogaizvrsitelja`.`id`
WHERE `ulogaizvrsitelja`.`naziv` = 'profesor'
  AND idKolegij NOT IN
      (SELECT DISTINCT (kolegiji.id)
       FROM kolegiji
                JOIN ocjene ON kolegiji.id = idKolegij
       WHERE ocjena = 1);

SELECT *
FROM prof_pozit;

SHOW CREATE VIEW studenti.prof_pozit;


/*Unaprijedivi pogled - primjer pogleda na tablicu radnik te izmjene, unosa i brisanja podataka.*/

CREATE OR REPLACE VIEW radnik_view AS
SELECT *
FROM radnik;

UPDATE radnik_view
SET `KoefPlaca` = 2.00;

SELECT *
FROM radnik_view;
SELECT *
FROM radnik;
--vidljivo je su se ažuriranjem podataka u pogledu ažurirali i podatci u bazi

INSERT INTO radnik_view (sifRadnik, imeRadnik, prezimeRadnik, pbrStan, sifOdjel)
VALUES (519, 'Ivan', 'Horvat', 331000, 5);

DELETE
FROM radnik_view
WHERE sifOdjel = 7;


/* Izraditi pogled recent_activity koji će prikazivati aktivnosti upisa studenata na smjer te polaganja kolegija. Za svaki zapis je potrebno ispisati o kojoj aktivnosti je riječ, podatke o studentu te opis sa nazivom kolegija ili smjera. Koristeći pogled potrebno je ispisati ispravno sortirane aktivnosti počevši od najnovije. */

CREATE OR REPLACE VIEW recent_activity AS
SELECT datumUpisa AS datum, 'upisan student', CONCAT(ime, " ", prezime, " ", jmbag) AS student, smjerovi.naziv AS opis
FROM studenti
         JOIN smjerovi ON studenti.idSmjer = smjerovi.id
UNION ALL
SELECT datumPolaganja                        AS datum,
       'unesena ocjena',
       CONCAT(ime, " ", prezime, " ", jmbag) AS student,
       kolegiji.naziv                        AS opis
FROM studenti
         JOIN ocjene ON studenti.jmbag = ocjene.jmbagStudent
         JOIN kolegiji ON ocjene.idKolegij = kolegiji.id;

SELECT *
FROM recent_activity
ORDER BY datum DESC;

/*Dohvat današnjih aktivnosti (kada bi baza bila live):*/
SELECT *
FROM recent_activity
WHERE datum = CURDATE()
ORDER BY datum DESC;


/* U bazi studenti: Izraditi pogled koji će ispisivati sortirani popis svih studenata sa njihovim prosjekom ocjena. Popis mora minimalno sadržavati:
- jmbag, 
- ime, 
- prezime i 
- prosječnu ocjenu studenta (zaokruženu na dvije decimale). 

Popis je potrebno sortirati po prosjeku i to od većeg prema manjem.
Koristeći izrađeni pogled, potrebno je ispisati:
a)	Sve studente i njihove prosjeke koji studiraju na Tehničkom veleučilištu u Zagrebu 
b)	Sve studente i njihove prosjeke koji studiraju na Međimurskom veleučilištu u Čakovcu te imaju prosjek 5.00
c)	Sve studente i njihove prosjeke koji studiraju na Fakultetu elektrotehnike i računarstva te imaju prosjek različit od 5.00
Napomena: primijetiti da ako je potrebno napraviti selekciju iz pogleda po određenom atributu (WHERE ustanove.naziv = „…“), da se taj atribut svakako mora nalaziti u projekciji pogleda (CREATE VIEW ime_pogleda AS SELECT ustanove.naziv,….)
 Očekivani rezultat c) zadatka je u nastavku.*/


CREATE OR REPLACE VIEW najbolji_studenti AS
SELECT jmbag, ime, prezime, ROUND(AVG(ocjena), 2) AS prosjek
FROM studenti
         JOIN ocjene ON jmbag = jmbagStudent
         JOIN smjerovi ON idSmjer = smjerovi.id
         JOIN ustanove ON oibUstanova = ustanove.oib
GROUP BY jmbag, ime, prezime
ORDER BY prosjek DESC;
#a)
SELECT *
FROM najbolji_studenti
WHERE naziv = "Tehničko veleučilište u Zagrebu"; /*GREŠKA U POGLEDU - Svakako moramo uključiti atribut naziv u prilikom izrade pogleda! */

CREATE OR REPLACE VIEW najbolji_studenti AS
SELECT jmbag, ime, prezime, ROUND(AVG(ocjena), 2) AS prosjek, ustanove.naziv
FROM studenti
         JOIN ocjene ON jmbag = jmbagStudent
         JOIN smjerovi ON idSmjer = smjerovi.id
         JOIN ustanove ON oibUstanova = ustanove.oib
GROUP BY jmbag, ime, prezime
ORDER BY prosjek DESC;

#a)
SELECT *
FROM najbolji_studenti
WHERE naziv = "Tehničko veleučilište u Zagrebu";
#b)
SELECT *
FROM najbolji_studenti
WHERE prosjek = 5.00
  AND naziv = "Međimursko veleučilište u Čakovcu";
#c)
SELECT *
FROM najbolji_studenti
WHERE prosjek != 5.00
  AND naziv = "Fakultet elektrotehnike i računarstva";



CREATE OR REPLACE VIEW recent_activity AS
SELECT datumUpisa                          AS datum,
       'upisan student'                    AS aktivnost,
       CONCAT_WS(' ', ime, prezime, jmbag) AS student,
       smjerovi.naziv                      AS opis
FROM studenti
         JOIN smjerovi ON studenti.idSmjer = smjerovi.id
UNION ALL
SELECT datumPolaganja                      AS datum,
       'unesena ocjena'                    AS aktivnost,
       CONCAT_WS(' ', ime, prezime, jmbag) AS student,
       kolegiji.naziv                      AS opis
FROM studenti
         JOIN ocjene ON studenti.jmbag = ocjene.jmbagStudent
         JOIN kolegiji ON ocjene.idKolegij = kolegiji.id;
SELECT *
FROM recent_activity
ORDER BY datum DESC;
# Dohvat današnjih aktivnosti (kada bi baza bila live):
SELECT *
FROM recent_activity
WHERE datum = CURDATE()
ORDER BY datum DESC