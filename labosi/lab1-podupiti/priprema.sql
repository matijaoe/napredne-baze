/* 1. U bazi autoradionica: Prikazati sve klijente sortirane po datumu prijave,
kao i naziv mjesta registracije i mjesta prebivališta. Klijente bez datuma ili s
nepravilnim datumom treba izostaviti.*/

SELECT datunosklijent,
       sifklijent,
       imeklijent,
       prezimeklijent,
       klijent.pbrklijent,
       mj_preb.nazivmjesto,
       klijent.pbrreg,
       mj_reg.nazivmjesto
FROM klijent
         JOIN mjesto AS mj_reg ON mj_reg.pbrmjesto = klijent.pbrreg
         JOIN mjesto AS mj_preb ON mj_preb.pbrmjesto = klijent.pbrklijent
WHERE datunosklijent IS NOT NULL
ORDER BY klijent.datunosklijent;


/* 2. U bazi studenti: Prikazati sve studente koji su imali negativne ocjene na
ispitima, broj negativnih ocjena i ostale atribute prema slici. Listu sortirati
po najvećem broju neg. ocjena padajući a zatim po imenu i prezimenu rastući.*/

SELECT s.ime, s.prezime, s.idsmjer, neg.*
FROM (SELECT jmbagstudent, COUNT(*) AS broj_negativnih
      FROM ocjene
      WHERE ocjena = 1
      GROUP BY jmbagstudent) neg
         JOIN studenti s ON neg.jmbagstudent = s.jmbag
ORDER BY neg.broj_negativnih DESC, s.ime, s.prezime;


/* 3. U bazi autoradionica: Prikazati sve radnike sortirane po imenu i prezimenu,
kao i broj odrađenih naloga te ukupnu sumu ostvarenih sati.*/
SELECT radnik.sifradnik,
       radnik.imeradnik,
       radnik.prezimeradnik,
       COUNT(n.sifradnik) AS broj_naloga,
       SUM(n.ostvarenisatirada)
FROM radnik
         NATURAL JOIN nalog n
GROUP BY radnik.sifradnik, radnik.imeradnik, radnik.prezimeradnik
ORDER BY 2, 3;


/* 4. U bazi autoradionica: Ispisati sve odjele koji pored naziva i šifre odjela,
sadrže šifru nadređenog odjela, broj radnika, minimalnu, maksimalnu i prosječnu
plaću odjela. Odjele sortirati po najvećem broju radnika padajući. */

SELECT o.nazivodjel,
       o.sifnadodjel                                AS sifnadodjel,
       o.sifodjel                                   AS sifodjel,
       COUNT(sifradnik)                             AS broj_radnika,
       ROUND(MIN(r.koefplaca * r.iznososnovice), 2) AS min_placa,
       ROUND(MAX(r.koefplaca * r.iznososnovice), 2) AS max_placa,
       ROUND(AVG(r.koefplaca * r.iznososnovice), 2) AS prosj_placa
FROM odjel o
         NATURAL JOIN radnik r
GROUP BY o.sifodjel
ORDER BY 4 DESC;

-- sluzb rjesenje
SELECT o.nazivodjel,
       o.sifnadodjel AS sifnadodjel,
       ag.*
FROM (SELECT sifodjel,
             COUNT(sifradnik)                             AS broj_radnika,
             ROUND(MIN(r.koefplaca * r.iznososnovice), 2) AS min_placa,
             ROUND(MAX(r.koefplaca * r.iznososnovice), 2) AS max_placa,
             ROUND(AVG(r.koefplaca * r.iznososnovice), 2) AS prosj_placa
      FROM radnik r
      GROUP BY sifodjel) ag
         NATURAL JOIN odjel o
ORDER BY 4 DESC;


/* 5. U bazi studenti: Prikazati listu studenata i njihovih prosječnih ocjena po
kolegijima. Pored toga prikazati i prosječnu ocjenu kolegija za sve studente i
broj ispita koji čini tu prosječnu ocjenu, prema slici. Sortirati po imenu,
prezimenu studenta.*
 */


SELECT s.ime, s.prezime, stu.*, kol.prosj_ocj_kol, kol.broj_ispita
FROM (SELECT jmbagstudent, idkolegij, AVG(ocjena) AS prosj_ocj
      FROM ocjene
      GROUP BY jmbagstudent, idkolegij) stu
         JOIN (SELECT idkolegij, AVG(ocjena) AS prosj_ocj_kol, COUNT(*) AS broj_ispita
               FROM ocjene
               GROUP BY idkolegij) kol ON stu.idkolegij = kol.idkolegij
         JOIN studenti s ON s.jmbag = stu.jmbagstudent
ORDER BY 1, 2


/* 6. U bazi autoradionica: Prikazati za sve nazive kvarova (iz šifarnika tj.
tablice KVAR) po godinama, broj izvršenih naloga i nominalan (PREDVIĐEN) broj
sati (satiKvar) kao i naziv odjela u kojem je odrađen kvar. Sortirati po šifri
kvara i godini.*/
SELECT k.sifkvar,
       k.nazivkvar,
       YEAR(n.datprimitkanalog) AS god,
       COUNT(n.sifkvar)         AS br_izvr_naloga,
       k.satikvar,
       o.nazivodjel
FROM kvar k
         NATURAL JOIN nalog n
         NATURAL JOIN odjel o
GROUP BY k.sifkvar, nazivkvar, YEAR(n.datprimitkanalog)
ORDER BY 1, 3;


SELECT k.sifkvar, k.nazivkvar, agr.god, br_izvrs_naloga, k.satikvar, o.nazivodjel
FROM (SELECT sifkvar, YEAR(datprimitkanalog) AS god, COUNT(*) AS br_izvrs_naloga
      FROM nalog n
      GROUP BY sifkvar, YEAR(datprimitkanalog)) agr
         RIGHT JOIN kvar k ON agr.sifkvar = k.sifkvar
         JOIN odjel o ON o.sifodjel = k.sifodjel
ORDER BY 1, 3;


-- PROSLOGODISNJI LABOSI

/*
1. U bazi studenti:
Koristeći JOIN naredbu potrebno je ispisati sve studente koji stanuju u Vukovarsko-srijemskoj županiji, a prebivaju u Splitsko-dalmatinskoj županiji.
Prikazati sve kolone studenata te naziva županija stanovanja i prebivanja (nazivima županija dati aliase zbog kontrole).
 */

SELECT s.*, z_stan.nazivzupanija AS zup_stanovanja, z_preb.nazivzupanija AS zup_prebivanja
FROM studenti s
         JOIN mjesta m_preb ON s.postbrprebivanje = m_preb.postbr
         JOIN mjesta m_stan ON s.postbrstanovanja = m_stan.postbr
         JOIN zupanije z_preb ON m_preb.idzupanija = z_preb.id
         JOIN zupanije z_stan ON m_stan.idzupanija = z_stan.id
WHERE z_stan.nazivzupanija LIKE 'Vukovarsko-srijemska%'
  AND z_preb.nazivzupanija LIKE 'Splitsko-dalmatinska%';

/*
 2. U bazi autoradionica: 
Ispisati sve naloge, prioriteta 1, sortirane po datumu primitka rastući, odrađene u prvoj polovini 2016 godine.
Prikazati šifru radnika, ime i prezime, inicijale imena i prezimena dopunjene točkama, naziv odjela, datum primitka i prioritet.
Svim kolonama dati aliase, kao i tablicama! 
Sortirati po šifri radnika.
*/

SELECT r.sifradnik,
       r.imeradnik,
       r.prezimeradnik,
       CONCAT(LEFT(r.imeradnik, 1), '.', LEFT(r.prezimeradnik, 1), '.') AS inicijali,
       o.nazivodjel,
       n.datprimitkanalog,
       n.prioritetnalog
FROM nalog n
         JOIN radnik r ON n.sifradnik = r.sifradnik
         JOIN odjel o ON r.sifodjel = o.sifodjel
WHERE prioritetnalog = 1
  AND QUARTER(datprimitkanalog) IN (1, 2)
ORDER BY datprimitkanalog;


-- proslogodisnji blic

/* U bazi radionica: Prikazati sve odrađene naloge po radnicima i šiframa klijenata.

Prikazati:  šifru radnika, šifru klijenta, broj naloga i ukupan broj sati po radniku i klijentu. U istom retku prikazati i
sveukupnu sumu sati po klijentu (od bilo kojeg radnika). Sortirati po  sumi sati radnika padajući i ograničiti prikaz
na prvih 1o redaka.
*/
SELECT n.sifradnik,
       n.sifklijent,
       COUNT(*)                 AS broj_naloga,
       SUM(n.ostvarenisatirada) AS broj_sati,
       klij.suma_sati_klijenta
FROM (SELECT k.sifklijent, SUM(n.ostvarenisatirada) AS suma_sati_klijenta
      FROM nalog n
               JOIN klijent k ON n.sifklijent = k.sifklijent
      GROUP BY k.sifklijent) klij
         JOIN nalog n ON n.sifklijent = klij.sifklijent
GROUP BY n.sifradnik, n.sifklijent;


SELECT nlg.*, klij.suma_sati_klijenta
FROM (SELECT k.sifklijent, SUM(n.ostvarenisatirada) AS suma_sati_klijenta
      FROM nalog n
               JOIN klijent k ON n.sifklijent = k.sifklijent
      GROUP BY k.sifklijent) klij
         JOIN (
    SELECT n.sifradnik,
           n.sifklijent,
           COUNT(*)                 AS broj_naloga,
           SUM(n.ostvarenisatirada) AS broj_sati
    FROM nalog n
    GROUP BY n.sifradnik, n.sifklijent) nlg ON nlg.sifklijent = klij.sifklijent;

/*
 U bazi radionica: Prikazati sve odrađene naloge po klijentima. Prikazati: šifru klijenta, prezime i ime klijenta,
 broj naloga i prosj sate za klijenta i njegovo mjesto prebivanja. Odabrati one klijente koji su imali više od 2 prosječna sata.
Sortirati po broju naloga klijenta padajući i prikazati prvih 1o klijenata
 */

SELECT k.sifklijent, k.prezimeklijent, k.imeklijent, ag_nal.broj_naloga, ag_nal.prosj_sati
FROM (SELECT sifklijent, COUNT(*) AS broj_naloga, AVG(ostvarenisatirada) AS prosj_sati
      FROM nalog
      GROUP BY sifklijent
      HAVING prosj_sati > 2) ag_nal
         JOIN klijent k ON k.sifklijent = ag_nal.sifklijent
ORDER BY broj_naloga DESC
LIMIT 10;

/* 4. U bazi studenti: Prikazati sve nastavnike koji su do sada na svim ispitima,
osim u 11 mjesecu bilo koje godine dali najmanje 1 a najviše 5 negativnih ocjena. Ispis sadrži sljedeće
podatke: jmbgNastavnika, titula ispred,  ime i prezime spojitu u jedan stupac, titulaiza, broj negativnih ocjena.
 Sortirati po broju ocjena padajući a zatim po imenu i prezimenu spojenom rastući.     */

SELECT nastavnici.jmbg,
       nastavnici.titulaispred,
       CONCAT_WS(' ', nastavnici.ime, nastavnici.prezime) AS ime_i_prezime,
       nastavnici.titulaiza,
       COUNT(ocjena)                                      AS broj_neg
FROM nastavnici
         JOIN izvrsitelji i ON nastavnici.jmbg = i.jmbgnastavnik
         JOIN kolegiji k ON k.id = i.idkolegij
         JOIN ocjene o ON k.id = o.idkolegij
WHERE ocjena = 1
  AND MONTH(datumpolaganja) != 11
GROUP BY nastavnici.jmbg
HAVING broj_neg BETWEEN 1 AND 5
ORDER BY broj_neg DESC, 3;


SELECT nastavnici.jmbg,
       nastavnici.titulaispred,
       CONCAT_WS(' ', nastavnici.ime, nastavnici.prezime) AS ime_i_prezime,
       nastavnici.titulaiza,
       neg.broj_neg
FROM (SELECT i.jmbgnastavnik, COUNT(ocjena) AS broj_neg
      FROM ocjene
               JOIN izvrsitelji i ON ocjene.idkolegij = i.idkolegij
      WHERE ocjena = 1
        AND MONTH(datumpolaganja) != 11
      GROUP BY i.jmbgnastavnik
      HAVING broj_neg BETWEEN 1 AND 5
     ) AS neg
         JOIN nastavnici ON neg.jmbgnastavnik = nastavnici.jmbg
ORDER BY broj_neg DESC, 3