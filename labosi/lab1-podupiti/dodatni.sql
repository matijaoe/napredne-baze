/* 1. U bazi autoradionica: Ispisati sve naloge, prioriteta 1, sortirane po datumu primitka rastući, odrađene u
prvoj polovini 2016 godine.
Prikazati šifru radnika, ime i prezime, inicijale imena i prezimena dopunjene točkama, naziv odjela, datum
primitka i prioritet.
Svim kolonama dati aliase, kao i tablicama! Sortirati po šifri radnika.
*/
SELECT r.sifradnik,
       r.imeradnik,
       r.prezimeradnik,
       CONCAT(LEFT(r.imeradnik, 1), '.', LEFT(r.prezimeradnik, 1), '.') AS inicijali,
       o.nazivodjel,
       datprimitkanalog,
       prioritetnalog
FROM nalog n
         NATURAL JOIN radnik r
         NATURAL JOIN odjel o
WHERE prioritetnalog = 1
  AND QUARTER(datprimitkanalog) IN (1, 2)
  AND YEAR(datprimitkanalog) = 2016
ORDER BY r.sifradnik;


/* 2. U bazi studenti: Po kolegijima prikazati sljedeće podatke: id kolegija, naziv kolegija, opis kolegija (prvih 50
znakova), broj ispita, min i max ocjenu iz kolegija (uzeti samo pozitivne ocjene).
Prikazati samo one koji su imali više od 3 pozitivna ispita. Sortirati po broju ispita padajući i ID kolegija rastući.*/
SELECT k.id, k.naziv, SUBSTR(k.opis, 1, 50) AS short_opis, ispiti.*
FROM (SELECT idkolegij, COUNT(*) AS broj_ispita, MIN(ocjena) AS min_ocjena, MAX(ocjena) AS max_ocjena
      FROM ocjene
      WHERE ocjena > 1
      GROUP BY idkolegij
      HAVING broj_ispita > 3) ispiti
         JOIN kolegiji k ON k.id = ispiti.idkolegij
ORDER BY broj_ispita DESC, k.id;

/* 3. U bazi autoradionica: Prikazati za sve radnike sljedeće podatke:
ime i prezime, koef plaće, sifru odjela, broj odrađenih naloga, sumu ostvarenih
sati. Prikazati prvi 18 radnika. Sortirati po imenu i prezimenu. */
SELECT r.imeradnik, r.prezimeradnik, r.koefplaca, r.sifodjel, agr.broj_naloga, agr.suma_sati
FROM (
         SELECT sifradnik, COUNT(*) AS broj_naloga, SUM(ostvarenisatirada) AS suma_sati
         FROM nalog
         GROUP BY sifradnik) agr
         JOIN radnik r ON r.sifradnik = agr.sifradnik
ORDER BY 1, 2
LIMIT 18;

/* 4. U bazi studenti: Prikazati sve nastavnike koji su do sada na svim ispitima, osim u 2. kvartalu,
ocijenili ocjenom DOVOLJAN (2) više od 2 studenta.
Ispis sadrži sljedeće podatke: jmbgNastavnika, ime, prezime, titulaiza, adresu, broj_ocjena.
Ime, prezime i titulaIza spojiti u jedan stupac, sortirati po broju ocjena padajući.
 */
SELECT n.jmbg                                        AS jmbgnastavnik,
       CONCAT_WS(' ', n.ime, n.prezime, n.titulaiza) AS ime_titula,
       n.adresa,
       agr.broj_ocj_2
FROM (SELECT i.jmbgnastavnik, COUNT(*) AS broj_ocj_2
      FROM ocjene
               JOIN kolegiji k ON ocjene.idkolegij = k.id
               JOIN izvrsitelji i ON k.id = i.idkolegij
      WHERE ocjena = 2
        AND QUARTER(datumpolaganja) != 2
        AND i.idulogaizvrsitelja = 1
      GROUP BY i.jmbgnastavnik
      HAVING broj_ocj_2 > 2) AS agr
         JOIN nastavnici n ON n.jmbg = agr.jmbgnastavnik
ORDER BY broj_ocj_2 DESC;

/* 5. U bazi radionica: Prikazati sve odrađene naloge po radnicima i šiframa kvarova.
Prikazati: ime i prezime radnika, šifru radnika, šifru kvara, broj naloga i prosj vrijeme po radniku i šifri
kvara. U istom retku prikazati i sveukupan broj naloga po kvaru.
Sortirati po šifri kvara i broju naloga.
*/
SELECT r.imeradnik, r.prezimeradnik, rd.*, kv.uk_broj_kvarova
FROM (SELECT sifradnik, sifkvar, COUNT(*) AS broj_naloga, AVG(ostvarenisatirada) AS prosj_vrijeme
      FROM nalog
      GROUP BY sifradnik, sifkvar) rd
         JOIN (SELECT sifkvar, COUNT(*) uk_broj_kvarova
               FROM nalog
               GROUP BY sifkvar) AS kv ON kv.sifkvar = rd.sifkvar
         JOIN radnik r ON r.sifradnik = rd.sifradnik
ORDER BY sifkvar, broj_naloga;

/* 6. U bazi autoradionica: Po mjesecima (bez obzira na godine) i vrstama kvarova prikazati sljedeće podatke:
mjesec, šifra kvara, broj naloga, prosječno ostvarene sate rada, naziv kvara, šifru odjela koji popravlja taj kvar.
Prikazati samo one vrste kvarova u mjesecu koji su se dogodili više od 3 puta. Sortirati po mjesecima i kvarovima
uzlazno. */
SELECT ng.*, k.nazivkvar, k.sifodjel
FROM (SELECT MONTH(datprimitkanalog) AS nh,
             sifkvar,
             COUNT(*)                AS broj_naloga,
             AVG(ostvarenisatirada)  AS prosj_sati
      FROM nalog n
      GROUP BY MONTH(datprimitkanalog), sifkvar
      HAVING broj_naloga > 3
     ) AS ng
         NATURAL JOIN kvar k
ORDER BY 1, 2;
