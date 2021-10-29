SELECT r.sifradnik as Sif_rad,
       CONCAT(LEFT(imeradnik, 1), '.', LEFT(prezimeradnik, 1), '.') AS inicijali,
       nazivodjel as Naz_Odj,
       datprimitkanalog as Dat_prim,
       nalog.prioritetnalog as Prioritet
FROM nalog
         JOIN radnik r ON nalog.sifradnik = r.sifradnik -- NATURAL JOIN radnik r
         JOIN odjel o ON r.sifodjel = o.sifodjel -- NATURAL JOIN odjel o
WHERE prioritetnalog = 1
  AND YEAR(datprimitkanalog) = 2016
  AND QUARTER(datprimitkanalog) IN (1, 2)
ORDER BY r.sifradnik -- ORDER BY 1





