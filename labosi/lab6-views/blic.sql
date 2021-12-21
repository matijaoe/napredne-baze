/* U bazi autoradionica: Izraditi pogled uz korištenje CTE-a koji će po kvartalima i radnicima sadržavati podatke prema
   slici lijevo (sort po kvartalu i šifri radnika).
   Nakon toga koristeći kreirani Pogled, prikazati podatke prema slici desno (sort po šifri odjela).
 */

CREATE OR REPLACE VIEW odjel_kvartali AS
WITH agr AS (
    SELECT QUARTER(datPrimitkaNalog) kvart, n.sifRadnik, COUNT(*) br_naloga, SUM(OstvareniSatiRada) suma_sati
    FROM nalog n
    GROUP BY QUARTER(datPrimitkaNalog), n.sifRadnik
)
SELECT agr.*, r.imeRadnik, r.prezimeRadnik, r.sifOdjel
FROM radnik r
         NATURAL JOIN agr
ORDER BY 1, 2;

-- default pogled
SELECT *
FROM odjel_kvartali;

-- podaci koristeci pogled
SELECT o.sifOdjel, o.nazivOdjel, SUM(p.br_naloga) ukup_br_naloga, SUM(p.suma_sati) ukup_suma_sati
FROM odjel_kvartali p
         NATURAL JOIN odjel o
GROUP BY o.sifOdjel, o.nazivOdjel
ORDER BY sifOdjel;