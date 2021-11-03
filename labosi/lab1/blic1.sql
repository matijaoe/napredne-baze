/* 4. U bazi studenti: Prikazati sve nastavnike koji su do sada na svim ispitima, osim u 11 mjesecu bilo koje
   godine dali najmanje 1 a najviše 5 negativnih ocjena. Ispis sadrži sljedeće podatke: jmbgNastavnika,
   titula ispred,  ime i prezime spojitu u jedan stupac, titulaiza, broj negativnih ocjena.
   Sortirati po broju ocjena padajući a zatim po imenu i prezimenu spojenom rastući.
*/

SELECT jmbgNastavnik,
       n.titulaIspred,
       CONCAT_WS(' ', n.ime, n.prezime) AS IME_PREZIME,
       n.titulaIza,
       br_ocj_1
FROM (SELECT jmbgNastavnik, COUNT(*) AS br_ocj_1
      FROM ocjene o
               JOIN izvrsitelji i ON o.idKolegij = i.idKolegij
      WHERE idUlogaIzvrsitelja = 1
        AND MONTH(datumPolaganja) <> 11
      GROUP BY jmbgNastavnik
      HAVING br_ocj_1 BETWEEN 1 AND 5
     ) AS agr
         JOIN nastavnici n ON n.jmbg = agr.jmbgNastavnik
ORDER BY br_ocj_1 DESC, n.ime, n.prezime;