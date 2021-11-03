/* Kako funkcioniraju spajanja tablica? */
SELECT *
FROM klijent,
     mjesto;

SELECT *
FROM klijent,
     mjesto
WHERE pbrklijent = pbrmjesto;

SELECT *
FROM klijent
         JOIN mjesto ON pbrklijent = pbrmjesto;

SELECT *
FROM klijent
         NATURAL JOIN mjesto;

SELECT *
FROM mjesto
         NATURAL JOIN zupanija;

# identicno ko natural join gore
SELECT *
FROM mjesto
         JOIN zupanija z ON mjesto.sifzupanija = z.sifzupanija;

SELECT *
FROM mjesto
         LEFT JOIN klijent ON pbrklijent = pbrmjesto;



/* Provjeriti je li nužno koristiti aliase prilikom ispisa podataka o mjestu stanovanja i mjestu registracije vozila za pojedinog klijenta? */
#Prirodni spoj - tablica mjesto koristi se dva puta za dva različita podatka - ali rezultat izvođenja vraća one n-torke gdje je mjesto registracije i stanovanja klijenta isto
SELECT *
FROM klijent,
     mjesto
WHERE klijent.pbrklijent = mjesto.pbrmjesto
  AND klijent.pbrreg = mjesto.pbrmjesto;

#Join za istu logiku rezultira sintaksnom pogreškom
SELECT imeklijent, prezimeklijent, nazivmjesto, nazivmjesto
FROM klijent
         JOIN mjesto
              ON pbrklijent = mjesto.pbrmjesto
         JOIN mjesto
              ON pbrreg = mjreg.pbrmjesto
WHERE pbrmjesto = pbrmjesto;

#Ispravno rješenje
SELECT imeklijent, prezimeklijent, mjstan.nazivmjesto, mjreg.nazivmjesto
FROM klijent
         JOIN mjesto AS mjstan
              ON pbrklijent = mjstan.pbrmjesto
         JOIN mjesto AS mjreg
              ON pbrreg = mjreg.pbrmjesto;

#Isti skup n-torki kao i prirodnim spojem u prvom koraku
SELECT imeklijent, prezimeklijent, mjstan.nazivmjesto, mjreg.nazivmjesto
FROM klijent,
     mjesto AS mjstan,
     mjesto AS mjreg
WHERE pbrklijent = mjstan.pbrmjesto
  AND pbrreg = mjreg.pbrmjesto;


/* Koliko se mjesta nalazi u svakoj županiji? */
#Korak po korak dolazimo do rezultata
SELECT *
FROM mjesto;

SELECT sifzupanija, COUNT(pbrmjesto) AS br
FROM mjesto
GROUP BY sifzupanija;

SELECT nazivzupanija, zupanija.sifzupanija, COUNT(*) AS br
FROM mjesto
         JOIN zupanija ON mjesto.sifzupanija = zupanija.sifzupanija
GROUP BY sifzupanija, nazivzupanija;

#Može li se ovdje korisiti vanjski spoj tablica?
SELECT nazivzupanija, zupanija.sifzupanija, COUNT(*) AS br
FROM mjesto
         RIGHT JOIN zupanija ON mjesto.sifzupanija = zupanija.sifzupanija
GROUP BY sifzupanija, nazivzupanija;


/* Ispisati radnike koji imaju koeficijent plaće veći od prosječnog.*/
SELECT sifradnik, koefplaca
FROM radnik
WHERE koefplaca >
      (SELECT AVG(koefplaca) FROM radnik);

/*Ispisati koliki je prosječni koeficijent plaće u svakom odjelu. Potrebno je ispisati samo one odjele u kojima je taj prosjek veći od prosječnog koeficijenta plaće po svim radnicima.*/
SELECT nazivodjel, AVG(koefplaca) AS prosjek
FROM radnik
         JOIN odjel ON radnik.sifodjel = odjel.sifodjel
GROUP BY nazivodjel
HAVING prosjek > (SELECT AVG(koefplaca) FROM radnik)
ORDER BY prosjek;


/*Potrebno je ispisati sumu broja sati kvara iz tablice kvar po imenu i 
prezimenu klijenta. Potrebno je ispisati one vrijednosti čije su sume 
veće od 5.*/
SELECT klijent.imeklijent,
       klijent.prezimeklijent,
       SUM(satikvar) AS
           suma
FROM kvar
         INNER JOIN
     nalog ON kvar.sifkvar = nalog.sifkvar
         INNER JOIN
     klijent ON nalog.sifklijent = klijent.sifklijent
GROUP BY klijent.prezimeklijent, klijent.imeklijent
HAVING suma > 5;

SELECT imeklijent, prezimeklijent, SUM(kvar.satikvar) AS suma_sati
FROM klijent
         NATURAL JOIN nalog
         NATURAL JOIN kvar
GROUP BY imeklijent, prezimeklijent
HAVING suma_sati > 5;

#Ovo ne radi:
/*U WHERE nikako ne smije doći agregatna funkcija!!!*/
SELECT klijent.imeklijent, klijent.prezimeklijent, SUM(satikvar)
FROM kvar
         INNER JOIN
     nalog ON kvar.sifkvar = nalog.sifkvar
         INNER JOIN
     klijent ON nalog.sifklijent = klijent.sifklijent
WHERE SUM(satikvar) > 5
GROUP BY klijent.prezimeklijent, klijent.imeklijent;


/*Ispisati sve radnike u čijim mjestima stanovanja ne živi ni jedan klijent.*/
SELECT *
FROM radnik
WHERE pbrstan NOT IN
      (SELECT pbrklijent FROM klijent);


SELECT *
FROM radnik
WHERE pbrstan <> ALL
      (SELECT pbrklijent FROM klijent);


/*Ispisati sve radnike u čijim mjestima stanovanja živi barem jedan klijent.*/
SELECT *
FROM radnik
WHERE pbrstan IN
      (SELECT pbrklijent FROM klijent);


/*Ispisati kvarove kod kojih su vrijednosti atributa satiKvar veće od svih vrijednosti  ostvarenih sati rada iz tablice nalog. (Upit ne vraća rezultat!)*/
SELECT *
FROM kvar
WHERE satikvar > ALL
      (SELECT ostvarenisatirada FROM nalog);


/*Potrebno je ispisati uvećane datume osnutka ustanova za tri mjeseca (baza studenti)*/

SELECT datumosnutka, ADDDATE(datumosnutka, INTERVAL 3 MONTH)
FROM ustanove;

SELECT datumosnutka, DATE_ADD(datumosnutka, INTERVAL 3 MONTH)
FROM ustanove;

SELECT datumosnutka, datumosnutka + INTERVAL 3 MONTH
FROM ustanove;


#ili:

SELECT SUBDATE(datumosnutka, INTERVAL -3 MONTH)
FROM ustanove;


/*Potrebno je ispisati sve ustanove koje su osnovane u trenutnom mjesecu*/
SELECT *
FROM ustanove
WHERE MONTH(datumosnutka) = MONTH(CURDATE());


/*Potrebno je ispisati datum osnutka ustanove po hrvatskim standardima. Znači, "DD.MM.YYYY."*/
SELECT DATE_FORMAT(datumosnutka, '%d.%m.%Y.')
FROM ustanove;


/*Potrebno je ispisati sve ustanove koje su osnovane na današnji datum bez obzira na godinu*/
SELECT *
FROM ustanove
WHERE DAY(datumosnutka) = DAY(CURDATE())
  AND MONTH(datumosnutka) = MONTH(CURDATE());

#ili:

SELECT *
FROM ustanove
WHERE DATE_FORMAT(datumosnutka, '%d%m') = DATE_FORMAT(CURDATE(), '%d%m');


/*Potrebno je iz JMBG-a nastavnika ispisati datume njihovih rođenja.*/
SELECT STR_TO_DATE(jmbg, '%d%m9%y')
FROM nastavnici;


/*Potrebno je provjeriti korisničku šifru nastavnika uz JMBG (za login npr.)*/
SELECT *
FROM nastavnici
WHERE jmbg = '0205951330124'
  AND lozinka = MD5('VedranGrubišić');


/*Enkriptiranje i dekriptiranje*/
SELECT AES_DECRYPT(AES_ENCRYPT(jmbg, 'Neki key'), 'Neki key')
FROM nastavnici;


/*Cast, tj. pretvaranje jednog tipa podatka u drugi tip podatka*/
SELECT CAST('1234567890' AS char(5));


/*Zašto je ovo neispravno!*/
SELECT *
FROM radnik
WHERE koefplaca = NULL;


/*Ispravno */
SELECT *
FROM radnik
WHERE koefplaca IS NULL;



/*LIMIT*/
#Potrebno je ispisati prvog klijenta po abecedi:
SELECT *
FROM klijent
ORDER BY prezimeklijent ASC, imeklijent ASC
LIMIT 0,1;
