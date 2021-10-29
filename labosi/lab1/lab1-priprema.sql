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

SELECT ime, prezime, idsmjer, jmbag, broj_negativnih
FROM (SELECT jmbagstudent, COUNT(*) AS broj_negativnih
      FROM ocjene
      WHERE ocjena = 1
      GROUP BY jmbagstudent) AS neg
         JOIN studenti ON studenti.jmbag = neg.jmbagstudent


/* 3. U bazi autoradionica: Prikazati sve radnike sortirane po imenu i prezimenu,
kao i broj odrađenih naloga te ukupnu sumu ostvarenih sati.*/
SELECT radnik.sifradnik,
       radnik.imeradnik,
       radnik.prezimeradnik,
       COUNT(n.sifradnik) AS broj_naloga,
       SUM(n.ostvarenisatirada)
FROM radnik
         JOIN nalog n ON radnik.sifradnik = n.sifradnik
GROUP BY radnik.sifradnik, radnik.imeradnik, radnik.prezimeradnik
ORDER BY 2, 3;

/* 5. U bazi studenti: Prikazati listu studenata i njihovih prosječnih ocjena po
kolegijima. Pored toga prikazati i prosječnu ocjenu kolegija za sve studente i
broj ispita koji čini tu prosječnu ocjenu, prema slici. Sortirati po imenu,
prezimenu studenta.*
 */

SELECT ime,
       prezime,
       s.jmbag,
       datumupisa,
       k.id,
       k.naziv,
       stu.prosj_ocj,
       kol.prosj_ocj_kol,
       kol.broj_ispita
FROM (SELECT jmbagstudent, idkolegij, AVG(ocjena) AS prosj_ocj
      FROM ocjene
      GROUP BY jmbagstudent, idkolegij) stu
         JOIN (
    SELECT idkolegij, AVG(ocjena) AS prosj_ocj_kol, COUNT(*) AS broj_ispita FROM ocjene GROUP BY idkolegij) kol
              ON stu.idkolegij = kol.idkolegij
         JOIN studenti s ON s.jmbag = stu.jmbagstudent
         JOIN kolegiji k ON k.id = kol.idkolegij;
