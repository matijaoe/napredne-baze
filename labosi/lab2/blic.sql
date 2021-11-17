/*
 za zadanu godinu prikazati po šifri kvara i prioritetu  podatke prema slici
 */

DELIMITER ##
DROP PROCEDURE IF EXISTS zadatak;
CREATE PROCEDURE zadatak(trazenaGodina INT)
BEGIN
    SELECT k.sifKvar, agr.prioritetNalog, k.nazivKvar, agr.br_naloga, agr.stdev_sati
    FROM (SELECT sifKvar, prioritetNalog, COUNT(*) br_naloga, ROUND(STDDEV(OstvareniSatiRada), 2) stdev_sati
          FROM nalog
          WHERE YEAR(datPrimitkaNalog) = trazenaGodina
          GROUP BY sifKvar, prioritetNalog
          HAVING stdev_sati > 0
         ) agr
             JOIN kvar k ON k.sifKvar = agr.sifKvar
    ORDER BY sifKvar;
END ##
DELIMITER ;

CALL zadatak(2017);