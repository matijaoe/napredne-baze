/* 1. Napisati proceduru koja će za zadanu šifru kvara preko izlaznih
parametara ispisati: naziv kvara, broj naloga i broj RAZLIČITIH klijenata koji
su imali taj kvar.
Ako nema tražene šifre u nalozima vraća poruku: "Nepostojeća šifra kvara".
Napisati smisleni primjer poziva ovog pohranjenog zadatka.*/
DELIMITER ##
DROP PROCEDURE IF EXISTS ispisiZaKvar;
CREATE PROCEDURE ispisiZaKvar(IN zadana_sifra INT, OUT broj_naloga INT, OUT broj_klijenata INT,
                              OUT naziv_kvara varchar(100))
BEGIN

    IF zadana_sifra IN (SELECT DISTINCT sifKvar FROM kvar) THEN
        SELECT DISTINCT k.nazivKvar, COUNT(*)
        INTO naziv_kvara, broj_naloga
        FROM nalog n
                 NATURAL JOIN kvar k
        WHERE sifKvar = 10;

        SELECT COUNT(DISTINCT k.sifKlijent)
        INTO broj_klijenata
        FROM klijent k
                 JOIN nalog n ON k.sifKlijent = n.sifKlijent
        WHERE n.sifKvar = zadana_sifra;
    ELSE
        SELECT 'Nepostojeća šifra kvara' AS poruka;
    END IF;
END ##
DELIMITER ;

CALL ispisiZaKvar(11, @brojn, @brojk, @nazivk);
SELECT @brojn, @brojk, @nazivk;
