/*
Dodijelite korisniku 'referent' dozvolu za čitanje i ažuriranje svih tablica u bazi AUTORADIONICA uz ograničenje
da može u jednom satu napraviti maksimalno 10 ažuriranja i 3 konekcije na bazu.
Dodijeliti  mu password 'ref_pass'.

Prikazati postavljene ovlasti. Ukinuti (samo one) dozvole koje su dodijeljene u ovom zadatku.
*/
CREATE USER 'referent'@'%' IDENTIFIED BY 'ref_pass';

GRANT SELECT, UPDATE ON autoradionica.* TO 'referent'@'%';
ALTER USER 'referent'@'%' IDENTIFIED BY 'ref_pass' WITH MAX_UPDATES_PER_HOUR 10 MAX_CONNECTIONS_PER_HOUR 3;


SHOW GRANTS FOR 'referent'@'%';
REVOKE SELECT, UPDATE ON autoradionica.* FROM 'referent'@'%';


/*
Napisati transakciju koja će zaključati n-torke u tablici REZERVACIJA i KVAR koje pripadaju
kvarovima

 'Zamjena vodene pumpe' i 'Ugradnja sportskog pojasa', te vratiti:

naziv kvara
sumu satServis po kvaru
Transakciju napisati na način  da druge sesije/transakcije ne mogu ni mijenjati niti čitati podatke o tim rezervacijama i kvarovima.

U drugoj sesiji:

Promijeniti atribut satServis tako da se poveća za 1.

Prokomentirati dobiveni rezultat.
*/
BEGIN;

SELECT k.nazivKvar, SUM(satServis) suma_sat_servis
FROM rezervacija
         JOIN kvar k ON rezervacija.sifKvar = k.sifKvar
WHERE k.nazivKvar IN ('Zamjena vodene pumpe', 'Ugradnja sportskog pojasa')
GROUP BY k.nazivKvar FOR UPDATE;

COMMIT;

# druga sesija

UPDATE rezervacija
SET satServis = satServis + 1;

/*Definiranjem FOR UPDATE zakljucavanja porucujemo da ce sadrzaj n-torki bit promijenjen,
  stoga drugim procesima nije dozvoljeno citanje niti mijenjanje podataka.
Tek pomocu COMMIT ce se te promjene odraditi ako timeout nije istekao.  */