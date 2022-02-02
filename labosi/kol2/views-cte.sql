/* 1. U bazi autoradionica: Izraditi pogled koji će vraćati popis svih naloga
zaprimljenih u drugoj polovini prosinca bilo koje godine. Osim svih podataka iz
tablice nalog, pogled mora vraćati i (samo) ime i prezime klijenta.
Ispisati cijeli skup podataka kojeg vraća pogled (napisati poziv pogleda).
Očekujemo ispis kao u nastavku. */


CREATE OR REPLACE VIEW nalozi_za_iducu_godinu AS
SELECT n.*, k.imeKlijent, k.prezimeKlijent
FROM nalog n
         NATURAL JOIN klijent k
WHERE MONTH(datPrimitkaNalog) = 12
  AND DAY(datPrimitkaNalog) > 15;

SELECT *
FROM nalozi_za_iducu_godinu;


/* 4. U bazi autoradionica:
Izraditi pogled uz korištenje CTE-a koji će za svaki kvar sadržavati podatke
prema slici:
   Koristeći kreirani pogled potrebno je ispisati za sve kvarove udio kvara u
ukupnom broju kvarova kao i šifru, naziv i broj kvarova.
 */


CREATE OR REPLACE VIEW kvar_podaci AS
WITH agr_kvar AS (
    SELECT sifKvar,
           COUNT(*)               br_kvarova,
           AVG(OstvareniSatiRada) pros_sati,
           SUM(OstvareniSatiRada) sum_sati,
           MIN(OstvareniSatiRada) min_sati,
           MAX(OstvareniSatiRada) max_sati
    FROM nalog n
    GROUP BY sifKvar
)
SELECT agr_kvar.*, k.nazivKvar, k.brojRadnika, k.satiKvar
FROM agr_kvar
         NATURAL JOIN kvar k
ORDER BY sifKvar;


# 1. pogled
SELECT *
FROM kvar_podaci;

# 2. koristeci kreirani pogled
SELECT sifKvar,
       nazivKvar,
       br_kvarova,
       br_kvarova / (SELECT SUM(br_kvarova) FROM kvar_podaci) * 100 AS udio
FROM kvar_podaci
GROUP BY sifKvar, nazivKvar
ORDER BY sifKvar;

-- ili
SELECT SUM(br_kvarova)
INTO @ukupna_suma
FROM kvar_podaci;
SELECT sifKvar,
       nazivKvar,
       br_kvarova,
       br_kvarova / @ukupna_suma * 100 AS udio
FROM kvar_podaci
GROUP BY sifKvar, nazivKvar
ORDER BY sifKvar;


/* 1. U bazi autoradionica:
Izraditi pogled uz korištenje CTE-a koji će po odjelima sadržavati sljedeće podatke prema slici (sort po nazivu
odjela):
   Koristeći kreirani pogled potrebno je po nadređenim odjelima prikazati ukupan broj naloga, ukupnu sumu sati za
one nadređene odjele koji imaju više od 1 naloga. Sort po šifri nadređenog odjela.
 */

CREATE OR REPLACE VIEW odjel_nalog AS
WITH agr_odjel AS (
    SELECT sifOdjel, COUNT(*) br_naloga, AVG(OstvareniSatiRada) prosj_sati, SUM(OstvareniSatiRada) sum_sati
    FROM nalog n
             JOIN kvar k ON n.sifKvar = k.sifKvar
    GROUP BY sifOdjel)
SELECT o.sifOdjel, o.nazivOdjel, br_naloga, prosj_sati, sum_sati, o.sifNadOdjel, nad_o.nazivOdjel AS nazNadrOdjel
FROM agr_odjel
         JOIN odjel o ON o.sifOdjel = agr_odjel.sifOdjel
         JOIN odjel nad_o ON nad_o.sifOdjel = o.sifNadOdjel
order by 2;

# a
SELECT *
FROM odjel_nalog;

# b
SELECT sifNadOdjel, nazNadrOdjel, SUM(br_naloga) ukupno_naloga, sum(sum_sati) ukupno_sati
FROM odjel_nalog
GROUP BY sifNadOdjel, nazNadrOdjel
having ukupno_naloga > 1
ORDER BY 1;

