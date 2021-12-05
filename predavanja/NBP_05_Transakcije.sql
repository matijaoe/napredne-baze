/*Kreiranje nove tablice 'menze' u bazi studenti sa InnoDB storage enginom.*/
USE studenti;
CREATE TABLE `menze` (
  `idMenze` INT(11) NOT NULL AUTO_INCREMENT,
  `naziv` VARCHAR(50) DEFAULT NULL,
  `adresa` VARCHAR(250) DEFAULT NULL,
  PRIMARY KEY (`idMenze`)
) ENGINE=INNODB DEFAULT CHARSET=utf8;




/*Provjera trenutnog stanja sesijske varijable AUTOCOMMIT u bazi information_schema u tablici SESSION_VARIABLES.*/
SELECT * FROM `information_schema`.`SESSION_VARIABLES` 
WHERE `information_schema`.`SESSION_VARIABLES`.variable_name="autocommit";
/* ili */
SHOW VARIABLES WHERE variable_name = "autocommit";





/*Unos nove n-torke u tablicu menze (id je definiran sa autoinkrementom).*/
INSERT INTO menze (naziv, adresa) 
	VALUES ('Menza FSB', 'Ivana Lučića 5');

SELECT * FROM menze;




/*Pokušaj unosa dvije nove menze u bazu podataka, tablicu 'menze'. Opoziv unosa.*/
SET autocommit=0;
SHOW VARIABLES WHERE variable_name = "autocommit";
START TRANSACTION; 
	INSERT INTO menze (naziv, adresa) VALUES ('Menza Voltino', 'Konavoska 2');
	INSERT INTO menze (naziv, adresa) VALUES ('Menza Vrbik', 'Vrbik 8a');
	SELECT * FROM menze;
ROLLBACK;
SET autocommit=1;

SELECT * FROM menze;





/*Pokušaj unosa dvije nove menze u bazu podataka, tablicu 'menze'. Potvrda unosa.*/
SET autocommit=0;
START TRANSACTION; 
	SHOW VARIABLES WHERE variable_name = "autocommit";
	INSERT INTO menze (naziv, adresa) VALUES ('Menza Vrbik', 'Vrbik 8a');
	INSERT INTO menze (naziv, adresa) VALUES ('Menza Voltino', 'Konavoska 2');
COMMIT;
SET autocommit=1;
SELECT * FROM menze;




/*Pokušaj unosa dvije nove menze u bazu podataka, tablicu 'menze2' koja NIJE na InnoDB storage enginu. Opoziv unosa.*/
USE studenti;
CREATE TABLE `menze2` (
  `idMenze` INT(11) NOT NULL AUTO_INCREMENT,
  `naziv` VARCHAR(50) DEFAULT NULL,
  `adresa` VARCHAR(250) DEFAULT NULL,
  PRIMARY KEY (`idMenze`)
) ENGINE=MYISAM  DEFAULT CHARSET=utf8;

SELECT * FROM menze2;
SET autocommit=0;
SHOW VARIABLES WHERE variable_name = "autocommit";
START TRANSACTION; 
	INSERT INTO menze2 (naziv, adresa) VALUES ('Menza Voltino', 'Konavoska 2');
	INSERT INTO menze2 (naziv, adresa) VALUES ('Menza Vrbik', 'Vrbik 8a');
ROLLBACK;
SET autocommit=1;
SELECT * FROM menze2;

	
			
/*Opoziv DDL naredbe ne funkcionira.*/
SET autocommit=0;
BEGIN WORK;
	CREATE TABLE `menze3` (
	  `idMenze` INT(11) NOT NULL AUTO_INCREMENT,
	  `naziv` VARCHAR(50) DEFAULT NULL,
	  `adresa` VARCHAR(250) DEFAULT NULL,
	  PRIMARY KEY (`idMenze`)
	)  DEFAULT CHARSET=utf8;
ROLLBACK;
SET autocommit=1;



/* DEMO 2 */

/*U bazi radionice, potrebno je povećati koeficijent plaće radniku Kruljac Petru za 0.5, te ga za isti iznos smanjiti radniku Parlov Dini. 
Potvrditi samo promjenu koeficijenta za radnika Kruljca, promjenu za Parlova opovrgnuti.*/
USE radionica;
SELECT * FROM radnik 
	WHERE (prezimeRadnik = 'Parlov' AND imeRadnik='Dino')
		OR (prezimeRadnik = 'Kruljac' AND imeRadnik='Petar') ;
SET AUTOCOMMIT = 0; 
BEGIN; 
	UPDATE radnik
		SET koefPlaca=koefPlaca+0.5 
		WHERE prezimeRadnik = 'Kruljac' AND imeRadnik='Petar'; 
	SAVEPOINT tocka;
	UPDATE radnik
		SET koefPlaca=koefPlaca-0.5 
		WHERE prezimeRadnik = 'Parlov' AND imeRadnik='Dino'; 
	SELECT * FROM radnik WHERE (prezimeRadnik = 'Kruljac' AND imeRadnik='Petar') 
		OR (prezimeRadnik = 'Parlov' AND imeRadnik='Dino');
	ROLLBACK TO SAVEPOINT tocka;
	SELECT * FROM radnik WHERE (prezimeRadnik = 'Kruljac' AND imeRadnik='Petar') 
		OR (prezimeRadnik = 'Parlov' AND imeRadnik='Dino');
COMMIT; 
SET AUTOCOMMIT = 1;


SELECT * FROM radnik WHERE (prezimeRadnik = 'Kruljac' AND imeRadnik='Petar') 
		OR (prezimeRadnik = 'Parlov' AND imeRadnik='Dino');




/* DEMO 3 */

/*Pogreške u transakciji - izvršit će se sve SQL naredbe koje su izvedive.*/
BEGIN WORK;
INSERT INTO menze VALUES(10, 'naziv1', 'adresa1');
INSERT INTO menze VALUES(10, 'naziv2', 'adresa2');
COMMIT WORK;
SELECT * FROM menze;






/*Pogreške u transakciji - pogreške unutar transakcije kojima aplikacija ne rukuje na eksplicitan način. Djeljenje s nulom rezultirati će NULL vrijednostima. */
USE radionica;
SELECT * FROM radnik;

UPDATE radnik SET koefPlaca=koefplaca/0;

SELECT * FROM radnik;




