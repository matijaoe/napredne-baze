/* 1. Postavite dozvole za prikaz i brisanje slogova u tablicama OCJENE i STUDENTI uz
korisniku „stud_user“ s lokalnog poslužitelja i dajte mu lozinku „loz“,
ograničenje da u satu može napraviti maksimalno 10 upita i 15 ažuriranja.
Prikazati postavljene ovlasti. Spojiti se na poslužitelj s novim podacima.

Riješiti istu funkcionalnost ali bez korištenja CREATE / GRANT naredbe već direktnim
promjenama (DDL) na bazi MySQL.
Ukinuti dozvole dodijeljene u ovom zadatku. */

DROP USER 'stud_user2'@'localhost';
CREATE USER 'stud_user2'@'localhost' IDENTIFIED BY 'loz';
GRANT SELECT, DELETE ON studenti.ocjene TO 'stud_user2'@'localhost';
ALTER USER 'stud_user2'@'localhost' WITH MAX_QUERIES_PER_HOUR 10 MAX_UPDATES_PER_HOUR 15;

GRANT SELECT, DELETE ON studenti.studenti TO 'stud_user2'@'localhost';
ALTER USER 'stud_user2'@'localhost' WITH MAX_QUERIES_PER_HOUR 10 MAX_UPDATES_PER_HOUR 15;

SELECT *
FROM mysql.columns_priv;

SHOW GRANTS FOR 'stud_user2'@'localhost';

REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'stud_user2'@'localhost';

INSERT INTO mysql.columns_priv (Host, Db, User, Table_name, Column_name, Timestamp, Column_priv)
VALUES ('localhost', 'studenti', 'stud_user', 'ocjene', 'root@localhost', '2018-12-06 11:51:56', 'Select,Delete');



-- labos
#1
UNLOCK TABLES;
CREATE USER 'voditelj'@'localhost' IDENTIFIED BY 'vod_lozfdfdsfdsfdssfdFDSsfdfds3';

GRANT UPDATE, CREATE ON radionica.radnik TO 'voditelj'@'localhost';
ALTER USER 'voditelj'@'localhost' WITH MAX_QUERIES_PER_HOUR 30 MAX_UPDATES_PER_HOUR 20;

GRANT UPDATE, INSERT ON radionica.nalog  TO 'voditelj'@'localhost'
    IDENTIFIED BY 'vod_loz' WITH max_queries_per_hour 30  max_updates_per_hour 20 ;

SHOW GRANTS FOR 'voditelj'@'localhost';
ALTER USER 'voditelj'@'localhost' IDENTIFIED BY 'vod passssssssssssssssssssssssss123S';

SELECT *
FROM mysql.user;

REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'voditelj'@'localhost';


SET GLOBAL validate_password.policy = 0;

#2
/* 2. Postavite dozvole za sve baze  i objekte korisniku „prof“  sa svih adresa) i dajte mu  lozinku  „prof_pass“,  uz
ograničenje da u satu može napraviti maksimalno  10 upita i 15 ažuriranja ograničenja u tablici kolegiji
   (može odabrati atribute:id, naziv; može ažurirati atribute: opis, smjer)ograničenja u tablici smjerovi
   (može odabrati atribut id; može ažurirati atribute: naziv, oibUstanova).
Prikazati postavljene ovlasti. Spojiti se na poslužitelj s novim podacima.


Ukinuti dozvole dodijeljene u ovom zadatku. */


CREATE USER 'prof'@'%' IDENTIFIED BY 'prof_pass';
GRANT ALL PRIVILEGES ON *.* TO 'prof'@'%' WITH GRANT OPTION;


GRANT SELECT (id, naziv ), UPDATE ( opis, idSmjer) ON studenti.kolegiji TO 'prof'@'%';
ALTER USER 'prof'@'%' WITH max_queries_per_hour 10  max_updates_per_hour 15;

GRANT SELECT (id ), UPDATE ( naziv, oibUstanova) ON studenti.smjerovi  TO 'prof'@'%';
ALTER USER 'prof'@'%' WITH max_queries_per_hour 10  max_updates_per_hour 15;

SHOW GRANTS FOR 'prof'@'%';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'prof'@'%';


SELECT *
FROM mysql.tables_priv;

INSERT into mysql.tables_priv
VALUES ('%', 'studenti', 'prof', 'smjerovi', 'root@localhost', '2018-01-06 10:21:56', '',
        'Select,Update', ''),
       ('%', 'studenti', 'prof', 'kolegiji', 'root@localhost', '2018-03-06 11:51:36', '',
        'Select,Update', '');