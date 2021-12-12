/* 1. U bazi autoradionica:
Izraditi pogled uz korištenje CTE-a koji će po odjelima sadržavati sljedeće podatke prema slici (sort po nazivu
odjela):

Koristeći kreirani pogled potrebno je po nadređenim odjelima prikazati ukupan broj naloga, ukupnu sumu sati za
one nadređene odjele koji imaju više od 1 naloga. Sort po šifri nadređenog odjela. */

CREATE OR REPLACE VIEW podaci_po_odjelu AS
WITH agr AS (
    SELECT k.sifOdjel, COUNT(*) br_naloga, AVG(OstvareniSatiRada) prosj_sati, SUM(OstvareniSatiRada) sum_sati
    FROM nalog n
             JOIN kvar k ON n.sifKvar = k.sifKvar
    GROUP BY k.sifOdjel
)
SELECT o.sifOdjel,
       o.nazivOdjel,
       agr.br_naloga,
       agr.prosj_sati,
       agr.sum_sati,
       o.sifNadOdjel,
       no.nazivOdjel AS nazNadrOdjel
FROM odjel o
         NATURAL JOIN agr
         JOIN odjel no ON o.sifNadOdjel = no.sifOdjel
ORDER BY o.sifNadOdjel;


SELECT sifNadOdjel, nazNadrOdjel, SUM(br_naloga) AS ukupno_naloga, SUM(sum_sati) AS ukupno_sati
FROM podaci_po_odjelu
GROUP BY sifNadOdjel, nazNadrOdjel
HAVING SUM(br_naloga) > 1;

-- vise od jednog odjela
SELECT sifNadOdjel, nazNadrOdjel, SUM(br_naloga) AS ukupno_naloga, SUM(sum_sati) AS ukupno_sati
FROM podaci_po_odjelu
GROUP BY sifNadOdjel, nazNadrOdjel
HAVING COUNT(*) > 1;

SELECT *
FROM podaci_po_odjelu;

/* 2. U bazi autoradionica: Izraditi pogled uz korištenje CTE-a koji će po godinama i kvarovima sadržavati podatke
prema slici (sort po godini i šifri kvara): */
CREATE OR REPLACE VIEW podaci_o_kvarovima AS
WITH agr AS (
    SELECT YEAR(datPrimitkaNalog) god,
           sifKvar,
           COUNT(*)               br_naloga,
           AVG(OstvareniSatiRada) prosj_sati,
           SUM(OstvareniSatiRada) sum_sati
    FROM nalog
    GROUP BY god, sifKvar
)
SELECT agr.*, k.nazivKvar, k.brojRadnika, k.satiKvar
FROM kvar k
         NATURAL JOIN agr
ORDER BY god, sifKvar;

/* Koristeći kreirani pogled potrebno je ispisati za sve vrste kvarova ( i one po kojima nije bilo naloga)
ukupan broj naloga, ukupnu sumu sati.*/

SELECT sifKvar, nazivKvar, COUNT(br_naloga) ukup_br_naloga, SUM(sum_sati) ukup_suma_sati
FROM podaci_o_kvarovima
GROUP BY sifKvar, nazivKvar
ORDER BY 1, 2;

SELECT k.sifKvar, k.nazivKvar, COUNT(br_naloga) ukup_br_naloga, SUM(sum_sati) ukup_suma_sati
FROM kvar k
         NATURAL LEFT JOIN podaci_o_kvarovima
GROUP BY k.sifKvar, k.nazivKvar
ORDER BY 1;


SELECT k.sifKvar, k.nazivKvar, agr.ukup_br_naloga, agr.ukup_suma_sati
FROM (SELECT sifKvar, COUNT(br_naloga) ukup_br_naloga, SUM(sum_sati) ukup_suma_sati
      FROM podaci_o_kvarovima
      GROUP BY sifKvar
      ORDER BY 1, 2) agr
         NATURAL RIGHT JOIN kvar k
ORDER BY 1;
