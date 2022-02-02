/* 1. U bazi autoradionica: Izraditi pogled koji će vraćati popis svih naloga
zaprimljenih u drugoj polovini prosinca bilo koje godine. Osim svih podataka iz
tablice nalog, pogled mora vraćati i (samo) ime i prezime klijenta.
Ispisati cijeli skup podataka kojeg vraća pogled (napisati poziv pogleda).
Očekujemo ispis kao u nastavku. */

CREATE OR REPLACE VIEW nalozi_druge_polovice_prosinca AS
SELECT n.*, r.imeRadnik, r.prezimeRadnik
FROM nalog n
         NATURAL JOIN radnik r
WHERE MONTH(datPrimitkaNalog) = 12
  AND DAY(datPrimitkaNalog) > 15;

SELECT *
FROM nalozi_druge_polovice_prosinca;

/* 2. U bazi autoradionica: Izraditi pogled koji će ispisati za svakog klijenta:
- Ime klijenta
- Prezime klijenta
- Naziv županije stanovanja
- Naziv mjesta stanovanja
- Naziv županije u kojoj su registrirali vozilo
- Naziv mjesta u kojem su registrirali vozilo
Koristeći izrađeni pogled potrebno je:
a) Ispisati cijeli skup podataka kojeg vraća pogled
b) Ispisati klijente koji imaju različitu županiju stanovanja i registracije
c) Ispisati klijente koji imaju istu županiju stanovanja i registracije, ali
različita mjesta
Za zadatak c) očekujemo ispis kao u nastavku: */

CREATE OR REPLACE VIEW mjesta_i_zupanije_klijenata AS
SELECT imeKlijent,
       prezimeKlijent,
       m1.nazivMjesto   mjesto_stan,
       z1.nazivZupanija zup_stan,
       m2.nazivMjesto   mjesto_reg,
       z2.nazivZupanija zup_reg
FROM klijent k
         JOIN mjesto m1 ON m1.pbrMjesto = k.pbrKlijent
         JOIN zupanija z1 ON z1.sifZupanija = m1.sifZupanija
         JOIN mjesto m2 ON m2.pbrMjesto = k.pbrReg
         JOIN zupanija z2 ON z2.sifZupanija = m2.sifZupanija;

# a
SELECT *
FROM mjesta_i_zupanije_klijenata;

# b
SELECT *
FROM mjesta_i_zupanije_klijenata
WHERE zup_reg <> zup_stan;

# c
SELECT *
FROM mjesta_i_zupanije_klijenata
WHERE zup_reg = zup_stan
  AND mjesto_reg <> mjesto_stan;


/* 3. U bazi autoradionica: Izraditi pogled koji će kronološki vraćati događaje
unesenih klijenata i zaprimljenih naloga. Događaje je potrebno sortirati od
najnovijeg prema najstarijem, pa nakon toga uzlazno po prezimenu. Očekujemo ispis
kako slijedi u nastavku.*/

CREATE OR REPLACE VIEW kronologija AS
SELECT 'zaprimljen nalog' dogadaj, imeKlijent, prezimeKlijent, datPrimitkaNalog datum
FROM nalog n
         NATURAL JOIN klijent k
UNION ALL
SELECT 'unesen klijent' dogadaj, imeKlijent, prezimeKlijent, datUnosKlijent datum
FROM klijent
ORDER BY 4 DESC, 3;

SELECT *
FROM kronologija;


/* 4. U bazi autoradionica:
Izraditi pogled uz korištenje CTE-a koji će za svaki kvar sadržavati podatke
prema slici:*/

CREATE OR REPLACE VIEW podaci_o_kvarovima AS
WITH cte_kvar AS (
    SELECT sifKvar,
           COUNT(*)               br_kvarova,
           AVG(OstvareniSatiRada) prosj_sati,
           SUM(OstvareniSatiRada) sum_sati,
           MIN(OstvareniSatiRada) min_sati,
           MAX(OstvareniSatiRada) max_sati
    FROM nalog
    GROUP BY sifKvar
)

SELECT c.*, k.nazivKvar, k.brojRadnika, k.satiKvar
FROM cte_kvar c
         JOIN kvar k ON k.sifKvar = c.sifKvar
ORDER BY sifKvar;

SELECT sifKvar, nazivKvar, br_kvarova, br_kvarova / (SELECT COUNT(*) FROM nalog) * 100 AS udio
FROM podaci_o_kvarovima;


/* 5. U bazi studenti: Izraditi pogled koji će ispisivati sortirani popis svih
studenata sa njihovim prosjekom ocjena. Popis mora minimalno sadržavati jmbag,
ime, prezime i prosječnu ocjenu studenta (zaokruženu na dvije decimale). Popis je
potrebno sortirati po prosjeku i to od većeg prema manjem.
Koristeći izrađeni pogled, potrebno je ispisati:
a) Sve studente i njihove prosjeke koji studiraju na Tehničkom veleučilištu u
Zagrebu
b) Sve studente i njihove prosjeke koji studiraju na Međimurskom veleučilištu u
Čakovcu te imaju prosjek 5.00
c) Sve studente i njihove prosjeke koji studiraju na Fakultetu elektrotehnike i
računarstva te imaju prosjek različit od 5.00
Napomena: primijetiti da ako je potrebno napraviti selekciju iz pogleda po
određenom atributu (WHERE ustanove.naziv = „…“), da se taj atribut svakako mora
nalaziti u projekciji pogleda (CREATE VIEW ime_pogleda AS SELECT
ustanove.naziv,….)
Očekivani rezultat c) zadatka je u nastavku.*/

CREATE OR REPLACE VIEW popis_studenata AS
SELECT s.jmbag, s.ime, s.prezime, ROUND(AVG(ocjena), 2) prosj_ocj, u.naziv
FROM ocjene o
         JOIN studenti s ON o.jmbagStudent = s.jmbag
         JOIN smjerovi s2 ON s.idSmjer = s2.id
         JOIN ustanove u ON s2.oibUstanova = u.oib
GROUP BY s.jmbag, s.ime, s.prezime
ORDER BY prosj_ocj DESC;

# a
SELECT *
FROM popis_studenata
WHERE naziv LIKE 'tehničko veleučilište%';

# b
SELECT *
FROM popis_studenata
WHERE naziv LIKE 'međimursko veleučilište%'
  AND prosj_ocj = 5;

# c
SELECT *
FROM popis_studenata
WHERE naziv LIKE 'Fakultet elektrotehnike%'
  AND prosj_ocj <> 5;


/* 6. U bazi studenti: Izraditi pogled koji će ispisivati za sva mjesta, podatke
o studentima koji u njima prebivaju te nastavnike koji su iz tog mjesta.
Ispis mora sadržavati kolone:
- Naziv mjesta
- Uloga (string 'student' ili 'nastavnik')
- Ime (studenta tj nastavnika)
- Prezime (studenta tj nastavnika)
- Jmbag tj. jmbg
Za dobivanje traženog popisa preporuča se korištenje unije.
Nakon toga je potrebno koristeći izrađeni pogled, ispisati samo zapise koji se
odnose na grad Zagreb. Očekujemo rezultat kako je vidljivo u nastavku (prikazan
je samo dio n-torki).*/

CREATE OR REPLACE VIEW nastavnici_i_studenti_mjesta AS
SELECT nazivMjesto, 'student' AS uloga, ime, prezime, jmbag AS jmbag_jmbg
FROM mjesta m
         JOIN studenti s ON m.postbr = s.postBrPrebivanje
UNION ALL
SELECT nazivMjesto, 'nastavnik' AS uloga, ime, prezime, jmbg AS jmbag_jmbg
FROM mjesta
         JOIN nastavnici n ON mjesta.postbr = n.postBr;

SELECT *
FROM nastavnici_i_studenti_mjesta
WHERE nazivMjesto = 'Zagreb'
ORDER BY prezime;


/* 7. U bazi studenti: Izraditi pogled koji će vraćati popis svih nastavnika u
formi:
- titula_ispred ime prezime, titula_iza -> stupac nazvati „Nastavnik“
- jmbg -> stupac nazvati „Jmbg“
- na koliko kolegija nastavnik ima ulogu profesora -> stupac nazvati „Profesor“
- na koliko kolegija nastavnik ima ulogu asistent -> stupac nazvati „Asistent“
Vrijednosti trećeg i četvrtog stupca moguće je računati pomoću podupita.
Koristeći izrađeni pogled, ispisati samo one nastavnike koji su profesori i
asistenti na istom broju kolegija. Očekujemo prikaz kao u nastavku. */

CREATE OR REPLACE VIEW uloge_nastavnika AS
SELECT CONCAT_WS(' ', n.titulaIspred, n.ime, n.prezime, n.titulaIza) AS nastavnik,
       jmbg                                                             jmbg_nastavnik,
       (
           SELECT COUNT(*)
           FROM izvrsitelji i
                    JOIN ulogaizvrsitelja u ON i.idUlogaIzvrsitelja = u.id
           WHERE u.naziv = 'profesor'
             AND i.jmbgNastavnik = jmbg
       )                                                                profesor,
       (
           SELECT COUNT(*)
           FROM izvrsitelji i
                    JOIN ulogaizvrsitelja u ON i.idUlogaIzvrsitelja = u.id
           WHERE u.naziv = 'asistent'
             AND i.jmbgNastavnik = jmbg
       )                                                                asistent
FROM nastavnici n
         JOIN izvrsitelji i ON n.jmbg = i.jmbgNastavnik;

SELECT *
FROM uloge_nastavnika
WHERE profesor = asistent;