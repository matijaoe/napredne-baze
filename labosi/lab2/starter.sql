# Procedure
DELIMITER ##
DROP PROCEDURE IF EXISTS zadProc;
CREATE PROCEDURE zadProc(IN arg1 INT, OUT arg2 INT)
BEGIN

END ##
DELIMITER ;

CALL zadProc(0, @a);
SELECT @a;


# Funkcije
DELIMITER ##
DROP FUNCTION IF EXISTS zadatak;
CREATE FUNCTION zadatak(arg INT) RETURNS VARCHAR(50)
    DETERMINISTIC
BEGIN

END ##
DELIMITER ;

SELECT zadatak(21);
