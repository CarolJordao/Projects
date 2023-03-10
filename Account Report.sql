USE new_schema;


/* BALANCE SHEET REPORT */

-- Creating a stored procedure begins with the delimiter and create procedure function. 
DROP PROCEDURE IF EXISTS balance_sheet;

DELIMITER $$
CREATE PROCEDURE balance_sheet(in calendaryear INT)
BEGIN
 
 /* Our first step was "cleaning" the messy database that we have. 
 For that, we decided to create a new table called table BS, which is going to be our new databse. 
 We included all the necessary information for the balance sheet from 4 main tables: account, journal_entry, 
 journal_entry_line_item and statement_section.
 We created the table using the "with" function and then we left-joined all the "new" single tables.
 */
 DROP TABLE IF EXISTS tableBS; 
CREATE TABLE tableBS AS (

						 WITH acco AS (SELECT `account`, account_id, balance_sheet_order, balance_sheet_section_id
										FROM `account`), 
						 
								ss AS (SELECT statement_section_id, statement_section_code, statement_section_order, is_balance_sheet_section
										FROM statement_section),
									
								jeli AS (SELECT journal_entry_id, account_id, `description`, IFNULL(debit, 0) AS debit, IFNULL(credit, 0) AS credit
										FROM journal_entry_line_item),
										
								je AS (SELECT journal_entry_id, journal_entry_code, journal_entry, entry_date, debit_credit_balanced, cancelled
									   FROM journal_entry)
						 
SELECT * 
FROM acco 
LEFT JOIN ss 
ON acco.balance_sheet_section_id = ss.statement_section_id
LEFT JOIN jeli 
USING (account_id)
LEFT JOIN je
USING (journal_entry_id)
);

/* After, we coded all the needed queries to get the balance of all the necessary accounts to build the report.
Assets includes "Current Assets", "Fixed Assets" and "Deferred Assets".
Liabilities includes "Current Liabilities", "Long Term Liabilities" and "Deferred Liabilities".
Equity includes only "Equity".
We filtered every query by the equivalent statement section id, by the entry date using the "YEAR" function 
and by including the non-cancelled values only. After, we built the query for the previous year as well.
Along the way, we used the "SET" function to build the formulas for the YoY growth and the total assets and liabilities.
*/

-- ------------------------------------------
-- CURRENT ASSETS
SELECT 
    (SUM(debit) - SUM(credit))
INTO @c_assets FROM
    tableBS
WHERE
    statement_section_id = 61
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- PREVIOUS CURRENT ASSETS
SELECT 
    (SUM(debit) - SUM(credit))
INTO @p_c_assets FROM
    tableBS
WHERE
    statement_section_id = 61
        AND YEAR(entry_date) = calendaryear - 1
        AND cancelled = 0;

SET @yoy_c_assets = ifnull(((@c_assets - @p_c_assets)/@p_c_assets * 100), 0);

-- FIXED ASSETS
SELECT 
    (SUM(debit) - SUM(credit))
INTO @f_assets FROM
    tableBS
WHERE
    statement_section_id = 62
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- PREVIOUS FIXED ASSETS
SELECT 
    (SUM(debit) - SUM(credit))
INTO @p_f_assets FROM
    tableBS
WHERE
    statement_section_id = 62
        AND YEAR(entry_date) = calendaryear - 1
        AND cancelled = 0;

SET @yoy_f_assets = ifnull(((@f_assets - @p_f_assets)/@p_f_assets * 100), 0);

-- DEFERRED ASSETS
SELECT 
    (SUM(debit) - SUM(credit))
INTO @d_assets FROM
    tableBS
WHERE
    statement_section_id = 63
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- PREVIOUS DEFERRED ASSETS
SELECT 
    (SUM(debit) - SUM(credit))
INTO @p_d_assets FROM
    tableBS
WHERE
    statement_section_id = 63
        AND YEAR(entry_date) = calendaryear - 1
        AND cancelled = 0;

SET @yoy_d_assets = ifnull(((@d_assets - @p_d_assets)/@p_d_assets * 100), 0);
SET @total_assets = ifnull(@c_assets, 0) + ifnull(@l_assets, 0) + ifnull(@d_assets, 0);
SET @p_total_assets = ifnull(@p_c_assets, 0) + ifnull(@p_l_assets, 0) + ifnull(@p_d_assets, 0);
SET @yoy_total_assets = ifnull(((@total_assets - @p_total_assets)/@p_total_assets * 100), 0);

-- ------------------------------------------
-- CURRENT LIABILITIES 
SELECT 
    SUM(credit) - SUM(debit)
INTO @c_liab FROM
    tableBS
WHERE
    statement_section_id = 64
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- PREVIOUS CURRENT LIABILITIES 
SELECT 
    (SUM(credit) - SUM(debit))
INTO @p_c_liab FROM
    tableBS
WHERE
    statement_section_id = 64
        AND YEAR(entry_date) = calendaryear - 1
        AND cancelled = 0;

SET @yoy_c_liab = ifnull(((@c_liab - @p_c_liab)/@p_c_liab * 100), 0);

-- LONG TERM LIABILITIES
SELECT 
    SUM(credit) - SUM(debit)
INTO @l_liab FROM
    tableBS
WHERE
    statement_section_id = 65
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- PREVIOUS LONG TERM LIABILITIES
SELECT 
    (SUM(credit) - SUM(debit))
INTO @p_l_liab FROM
    tableBS
WHERE
    statement_section_id = 65
        AND YEAR(entry_date) = calendaryear - 1
        AND cancelled = 0;

SET @yoy_l_liab = ifnull(((@l_liab - @p_l_liab)/@p_l_liab * 100), 0);

-- DEFERRED LIABILITIES
SELECT 
    SUM(credit) - SUM(debit)
INTO @d_liab FROM
    tableBS
WHERE
    statement_section_id = 66
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- PREVIOUS DEFERRED LIABILITIES
SELECT 
    (SUM(credit) - SUM(debit))
INTO @p_d_liab FROM
    tableBS
WHERE
    statement_section_id = 66
        AND YEAR(entry_date) = calendaryear - 1
        AND cancelled = 0;

SET @yoy_d_liab = ifnull(((@d_liab - @p_d_liab)/@p_d_liab * 100), 0);
SET @total_liab = ifnull(@c_liab, 0) + ifnull(@l_liab, 0) + ifnull(@d_liab, 0);
SET @p_total_liab = ifnull(@p_c_liab, 0) + ifnull(@p_l_liab, 0) + ifnull(@p_d_liab, 0);
SET @yoy_total_liab = ifnull(((@total_liab - @p_total_liab)/@p_total_liab * 100), 0);

-- ------------------------------------------
-- EQUITY
SELECT 
    (SUM(credit) - SUM(debit))
INTO @eq FROM
    tableBS
WHERE
    statement_section_id = 67
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- PREVIOUS EQUITY
SELECT 
    (SUM(credit) - SUM(debit))
INTO @p_eq FROM
    tableBS
WHERE
    statement_section_id = 67
        AND YEAR(entry_date) = calendaryear - 1
        AND cancelled = 0; 

SET @yoy_eq = ifnull(((@eq - @p_eq)/@p_eq * 100), 0);
SET @total_eq = ifnull(@eq, 0);
SET @p_total_eq = ifnull(@p_eq, 0);
SET @yoy_total_eq = ifnull(((@total_eq - @p_total_eq)/@p_total_eq * 100), 0);

-- ------------------------------------------
-- Building the balance sheet report
/* To build the balance sheet report, we created a table with 5 columns and we inserted all the rows one-by-one, 
including the equivalent formulas. We cleaned the output results using the FORMAT and COALESCE functions. 
*/

DROP TABLE IF EXISTS balance_sheet_report;

CREATE TABLE balance_sheet_report (
    category VARCHAR(50),
    subcategory VARCHAR(50),
    `current year` VARCHAR(20),
    `previous year` VARCHAR(20),
    `YOY growth` VARCHAR(20)
);

INSERT INTO balance_sheet_report(category, subcategory, `current year`, `previous year`, `YOY growth`)
VALUES  ('BALANCE SHEET', ' ','in usd','in usd','in %'),
		('--------------', '--------------',calendaryear, calendaryear - 1, '--------------'),
        ('ASSETS', ' ',' ',' ', ' '),
		(' ',  'TOTAL', format(@total_assets, 0), format(@p_total_assets, 0), format(@yoy_total_assets, 0)),
		(' ',  'CURRENT ASSETS', format(coalesce(@c_assets, 0),0), format(coalesce(@p_c_assets, 0),0), format(coalesce(@yoy_c_assets, 0),0)),
		(' ',  'FIXED ASSETS', format(coalesce(@f_assets, 0), 0), format(coalesce(@p_f_assets, 0), 0), format(coalesce(@yoy_f_assets, 0), 0)),
		(' ',  'DEFERRED ASSETS', format(coalesce(@d_assets, 0), 0), format(coalesce(@p_d_assets, 0), 0), format(coalesce(@yoy_d_assets, 0), 0)),
		('--------------', '--------------','--------------','--------------','--------------'),
        ('LIABILITIES', ' ',' ',' ', ' '),
        (' ',  'TOTAL', format(@total_liab, 0), format(@p_total_liab, 0), format(@yoy_total_liab, 0)),
        (' ', 'CURRENT LIABILITIES', format(coalesce(@c_liab, 0), 0), format(coalesce(@p_c_liab, 0), 0), format(coalesce(@yoy_c_liab, 0), 0)),
		(' ', 'LONG TERM LIABILITIES', format(coalesce(@l_liab, 0), 0), format(coalesce(@p_l_liab, 0), 0), format(coalesce(@yoy_l_liab, 0), 0)),
		(' ', 'DEFERRED LIABILITIES', format(coalesce(@d_liab, 0), 0), format(coalesce(@p_d_liab, 0), 0), format(coalesce(@yoy_d_liab, 0), 0)),
		('--------------', '--------------','--------------','--------------','--------------'),
        ('EQUITY', ' ',format(@total_eq, 0),format(@p_total_eq, 0), ' '),
        (' ', 'TOTAL', format(coalesce(@eq, 0), 0), format(coalesce(@p_eq, 0), 0), format(coalesce(@yoy_eq, 0), 0))
        
        ;
        


END $$
DELIMITER ;

CALL balance_sheet(2016);
SELECT * FROM balance_sheet_report;


/* PROFIT AND LOSS REPORT */

DROP PROCEDURE IF EXISTS pl_statement;

DELIMITER $$
CREATE PROCEDURE pl_statement (IN calendaryear INT)
BEGIN

-- Declaring all the variables that are being used as a method of calculation in the PL statement
DECLARE varREV 							DOUBLE DEFAULT 0;
DECLARE varRET 							DOUBLE DEFAULT 0;
DECLARE varCOGS  						DOUBLE DEFAULT 0;
DECLARE varGEXP 						DOUBLE DEFAULT 0;
DECLARE varSEXP 						DOUBLE DEFAULT 0;
DECLARE varOEXP 						DOUBLE DEFAULT 0;
DECLARE varOINC 						DOUBLE DEFAULT 0;
DECLARE varINCTAX 						DOUBLE DEFAULT 0;
DECLARE varOTHTAX						DOUBLE DEFAULT 0;
DECLARE varOTHINC						DOUBLE DEFAULT 0;
DECLARE varREVpreviousyear 				DOUBLE DEFAULT 0;
DECLARE varRETpreviousyear 				DOUBLE DEFAULT 0;
DECLARE varCOGSpreviousyear 			DOUBLE DEFAULT 0;
DECLARE varGEXPpreviousyear 			DOUBLE DEFAULT 0;
DECLARE varSEXPpreviousyear 			DOUBLE DEFAULT 0;
DECLARE varOEXPpreviousyear 			DOUBLE DEFAULT 0;
DECLARE varOINCpreviousyear				DOUBLE DEFAULT 0;
DECLARE varINCTAXpreviousyear 			DOUBLE DEFAULT 0;
DECLARE varOTHTAXpreviousyear 			DOUBLE DEFAULT 0;
DECLARE varOTHINCpreviousyear 			DOUBLE DEFAULT 0;
DECLARE varREVyoy						DOUBLE DEFAULT 0;
DECLARE varRETyoy						DOUBLE DEFAULT 0;
DECLARE varCOGSyoy						DOUBLE DEFAULT 0;
DECLARE varGEXPyoy						DOUBLE DEFAULT 0;
DECLARE varSEXPyoy						DOUBLE DEFAULT 0;
DECLARE varOEXPyoy						DOUBLE DEFAULT 0;
DECLARE varOINCyoy						DOUBLE DEFAULT 0;
DECLARE varINCTAXyoy					DOUBLE DEFAULT 0;
DECLARE varOTHTAXyoy					DOUBLE DEFAULT 0;
DECLARE varOTHINCyoy					DOUBLE DEFAULT 0;
DECLARE varGPM							DOUBLE DEFAULT 0;
DECLARE varGPMpreviousyear				DOUBLE DEFAULT 0;
DECLARE varGPMperc						DOUBLE DEFAULT 0;
DECLARE varGPMpercpreviousyear			DOUBLE DEFAULT 0;
DECLARE varGPMyoy						DOUBLE DEFAULT 0;
DECLARE varNI							DOUBLE DEFAULT 0;
DECLARE varNIpreviousyear				DOUBLE DEFAULT 0;
DECLARE varNIyoy						DOUBLE DEFAULT 0;
DECLARE varREVt							DOUBLE DEFAULT 0;
DECLARE varREVtpreviousyear				DOUBLE DEFAULT 0;
DECLARE varREVtyoy						DOUBLE DEFAULT 0;
DECLARE varNIperc						DOUBLE DEFAULT 0;
DECLARE varNIpercpreviousyear			DOUBLE DEFAULT 0;
DECLARE varNIpercyoy					DOUBLE DEFAULT 0;

-- Dropping the table if it already exists
DROP TABLE IF EXISTS PL;

-- Creating the temporary table from which we will be querying the data from; its a table in which all the data is combined in one big table so that queries can be made shorter without all the joins for each individual query
CREATE TABLE PL AS (
		WITH 	acco AS (SELECT account_id, profit_loss_order, profit_loss_section_id
						FROM `account`),
                
                ss AS (SELECT statement_section_id, statement_section_code, statement_section, statement_section_order, debit_is_positive
						FROM statement_section),
                        
				jeli AS (SELECT journal_entry_id, account_id, IFNULL(debit,0) AS debit, IFNULL(credit,0) AS credit
						FROM journal_entry_line_item),
                        
				je AS 	(SELECT journal_entry_id, entry_date, journal_type_id, journal_entry_code, journal_entry, debit_credit_balanced, cancelled, audited, closing_type
						FROM journal_entry)

-- Joining all the tables together, so that we won't have to repeat this throughout the stored procedure
SELECT *
FROM acco
LEFT JOIN ss
	ON ss.statement_section_id = acco.profit_loss_section_id 
LEFT JOIN jeli
	USING (account_id)
LEFT JOIN je
	USING (journal_entry_id)
);

-- Below we calculate the each field of the PL statement using the variables which we declared in the section above

-- Revenues
SELECT 	SUM(credit) INTO varREV
FROM 	PL
WHERE 	statement_section_code = 'REV'
AND 	YEAR(entry_date) = calendaryear
AND 	cancelled = 0;

-- Revenues previous year
SELECT 	SUM(credit) INTO varREVpreviousyear
FROM 	PL
WHERE 	statement_section_code = 'REV'
AND 	YEAR(entry_date) = calendaryear-1
AND 	cancelled = 0;

SET 	varREVyoy = IFNULL(((varREV - varREVpreviousyear)/varREVpreviousyear * 100),0);

-- Return, Refunds and Discounts
SELECT 	SUM(debit) INTO varRET
FROM 	PL
WHERE 	statement_section_code = 'RET'
AND 	YEAR(entry_date) = calendaryear
AND 	cancelled = 0;

-- Return, Refunds and Discounts previous year
SELECT 	SUM(debit) INTO varRETpreviousyear
FROM 	PL
WHERE 	statement_section_code = 'RET'
AND 	YEAR(entry_date) = calendaryear-1
AND 	cancelled = 0;

SET 	varRETyoy = IFNULL(((varRET - varRETpreviousyear)/varRETpreviousyear * 100),0);

-- Cost of Goods and Services
SELECT 	SUM(debit) INTO varCOGS
FROM 	PL
WHERE 	statement_section_code = 'COGS'
AND 	YEAR(entry_date) = calendaryear
AND 	cancelled = 0;

-- Cost of Goods and Services previous year
SELECT 	SUM(debit) INTO varCOGSpreviousyear
FROM 	PL
WHERE 	statement_section_code = 'COGS'
AND 	YEAR(entry_date) = calendaryear-1
AND 	cancelled = 0;

SET 	varCOGSyoy = IFNULL(((varCOGS - varCOGSpreviousyear)/varCOGSpreviousyear * 100),0);

-- Administrative Expenses
SELECT 	SUM(debit) - SUM(credit) INTO varGEXP
FROM 	PL
WHERE 	statement_section_code = 'GEXP'
AND 	YEAR(entry_date) = calendaryear
AND 	cancelled = 0;

-- Administrative Expenses pervious year
SELECT 	SUM(debit) - SUM(credit) INTO varGEXPpreviousyear
FROM 	PL
WHERE 	statement_section_code = 'GEXP'
AND 	YEAR(entry_date) = calendaryear-1
AND 	cancelled = 0;

SET 	varGEXPyoy = IFNULL(((varGEXP - varGEXPpreviousyear)/varGEXPpreviousyear * 100),0);

-- Selling Expenses
SELECT 	SUM(debit) INTO varSEXP
FROM 	PL
WHERE 	statement_section_code = 'SEXP'
AND 	YEAR(entry_date) = calendaryear
AND 	cancelled = 0;

-- Selling Expenses previous year
SELECT 	SUM(debit) INTO varSEXPpreviousyear
FROM 	PL
WHERE 	statement_section_code = 'SEXP'
AND 	YEAR(entry_date) = calendaryear-1
AND 	cancelled = 0;

SET 	varSEXPyoy = IFNULL(((varSEXP - varSEXPpreviousyear)/varSEXPpreviousyear * 100),0);

-- Other expenses
SELECT 	SUM(debit) INTO varOEXP
FROM 	PL
WHERE 	statement_section_code = 'OEXP'
AND 	YEAR(entry_date) = calendaryear
AND 	cancelled = 0;

-- Other expenses previous year
SELECT 	SUM(debit) INTO varOEXPpreviousyear
FROM 	PL
WHERE 	statement_section_code = 'OEXP'
AND 	YEAR(entry_date) = calendaryear-1
AND 	cancelled = 0;

SET 	varOEXPyoy = IFNULL(((varOEXP - varOEXPpreviousyear)/varOEXPpreviousyear * 100),0);

-- Other income
SELECT 	SUM(debit) INTO varOTHINC
FROM 	PL
WHERE 	statement_section_code = 'OTHINC'
AND 	YEAR(entry_date) = calendaryear
AND 	cancelled = 0;

-- Other income previous year
SELECT 	SUM(debit) INTO varOTHINCpreviousyear
FROM 	PL
WHERE 	statement_section_code = 'OTHINC'
AND 	YEAR(entry_date) = calendaryear-1
AND 	cancelled = 0;

SET 	varOTHINCyoy = IFNULL(((varOTHINC - varOTHINCpreviousyear)/varOTHINCpreviousyear * 100),0);

-- Income Tax
SELECT 	SUM(debit) INTO varINCTAX
FROM 	PL
WHERE 	statement_section_code = 'INCTAX'
AND 	YEAR(entry_date) = calendaryear
AND 	cancelled = 0;

-- Income Tax previous year
SELECT 	SUM(debit) INTO varINCTAXpreviousyear
FROM 	PL
WHERE 	statement_section_code = 'INCTAX'
AND 	YEAR(entry_date) = calendaryear-1
AND 	cancelled = 0;

SET 	varINCTAXyoy = IFNULL(((varINCTAX - varINCTAXpreviousyear)/varINCTAXpreviousyear * 100),0);

-- Other Tax
SELECT 	SUM(debit) - SUM(credit) INTO varOTHTAX
FROM 	PL
WHERE 	statement_section_code = 'OTHTAX'
AND 	YEAR(entry_date) = calendaryear
AND 	cancelled = 0;

-- Other Tax previous year
SELECT 	SUM(debit) INTO varOTHTAXpreviousyear
FROM 	PL
WHERE 	statement_section_code = 'OTHTAX'
AND 	YEAR(entry_date) = calendaryear-1
AND 	cancelled = 0;

SET 	varOTHTAXyoy = IFNULL(((varOTHTAX - varOTHTAXpreviousyear)/varOTHTAXpreviousyear * 100),0);

-- This block includes all the formulas which are needed to do the necessary calculations within the PL statement
SET varGPM 					= IFNULL((varREV - varCOGS),0); 									
SET varGPMperc 				= IFNULL((varGPM / varREV) * 100,0);
SET varREVt 				= IFNULL(varREV,0) + IFNULL(varOINC,0) - IFNULL(varRET,0);
SET varGPMpreviousyear 		= IFNULL((varREVpreviousyear - varCOGSpreviousyear),0); 						
SET varGPMpercpreviousyear 	= IFNULL((varGPMpreviousyear / varREVpreviousyear) * 100,0);
SET varGPMyoy 				= IFNULL((varGPMperc - varGPMpercpreviousyear) / (varGPMpercpreviousyear) * 100,0);
SET varNI 					= IFNULL(varREVt,0) - IFNULL(varCOGS,0) - IFNULL(varGEXP,0) - IFNULL(varSEXP, 0) - IFNULL(varOEXP, 0) - IFNULL(varINCTAX,0) - IFNULL(varOTHTAX,0);
SET varREVtpreviousyear 	= IFNULL(varREVpreviousyear,0) + IFNULL(varOINCpreviousyear,0) - IFNULL(varRETpreviousyear,0);
SET varNIpreviousyear 		= IFNULL(varREVtpreviousyear,0) - IFNULL(varCOGSpreviousyear,0) - IFNULL(varGEXPpreviousyear,0) - IFNULL(varSEXPpreviousyear, 0) - IFNULL(varOEXPpreviousyear, 0) - IFNULL(varINCTAXpreviousyear,0) - IFNULL(varOTHTAXpreviousyear,0);
SET varNIyoy 				= IFNULL((varNI - varNIpreviousyear) / (varNIpreviousyear) * 100,0);
SET varREVtyoy 				= IFNULL((varREVt - varREVtpreviousyear) / (varREVtpreviousyear) * 100,0);
SET varNIperc				= IFNULL((varNI / varREVt) * 100,0);
SET varNIpercpreviousyear	= IFNULL((varNIpreviousyear / varREVtpreviousyear) * 100,0);
SET varNIpercyoy			= IFNULL((varNIperc - varNIpercpreviousyear) / (varNIpercpreviousyear) * 100,0);


DROP TABLE IF EXISTS pl_statement;

-- WE hereby create the phsyical PL statement table which will be the foundation of our output in the terminal once the stored procedure is called. 
CREATE TABLE pl_statement( 
`Account Name` 			VARCHAR(50),
`Amount This Year` 		VARCHAR(50),
`Amount Previous Year` 	VARCHAR(50),
`YoY Growth(%)` 		VARCHAR(50)
);

-- This is where we insert the values of all the calculations (used above) and put them inside our PL statement
INSERT INTO pl_statement(`Account Name`, `Amount This Year`, `Amount Previous Year`, `YoY Growth(%)`)
VALUES
('Profit & Loss Report' , 'in USD', 'in USD', 'in %'),

(calendaryear, '','',''),

('--------------', '--------------','--------------','--------------'),

('REVENUES', FORMAT(COALESCE(varREV,0),0), FORMAT(COALESCE(varREVpreviousyear,0),0), FORMAT(COALESCE(varREVyoy,0),0)),

('OTHER INCOME', FORMAT(COALESCE(varOTHINC,0),0), FORMAT(COALESCE(varOTHINCpreviousyear,0),0), FORMAT(COALESCE(varOTHINCyoy,0),0)),

('RETURN, REFUNDS AND DISCOUNTS', FORMAT(COALESCE(varRET,0),0), FORMAT(COALESCE(varRETpreviousyear,0),0), FORMAT(COALESCE(varRETyoy,0),0)),

('TOTAL REVENUES', FORMAT(COALESCE(varREVt,0),0), FORMAT(COALESCE(varREVtpreviousyear,0),0), FORMAT(COALESCE(varREVtyoy,0),0)),

('--------------', '--------------','--------------','--------------'),

('COST OF GOODS AND SERVICES', FORMAT(COALESCE(varCOGS,0),0), FORMAT(COALESCE(varCOGSpreviousyear,0),0), FORMAT(COALESCE(varCOGSyoy,0),0)),

('GROSS PROFIT MARGIN', FORMAT(COALESCE(varGPM,0),0), FORMAT(COALESCE(varREVpreviousyear - varCOGSpreviousyear,0),0), FORMAT(COALESCE(((varREV - varCOGS) - (varREVpreviousyear - varCOGSpreviousyear)) / (varREVpreviousyear - varCOGSpreviousyear) * 100,0),0)),

('GROSS PROFIT MARGIN %', FORMAT(COALESCE(varGPMperc,0),0) , FORMAT(COALESCE(varGPMpercpreviousyear,0),0), FORMAT(COALESCE(varGPMyoy,0),0)), 

('--------------', '--------------','--------------','--------------'),

('ADMINISTRATIVE EXPENSES', FORMAT(COALESCE(varGEXP,0),0), FORMAT(COALESCE(varGEXPpreviousyear,0),0), FORMAT(COALESCE(varGEXPyoy,0),0)),

('SELLING EXPENSES', FORMAT(COALESCE(varSEXP,0),0), FORMAT(COALESCE(varSEXPpreviousyear,0),0), FORMAT(COALESCE(varSEXPyoy,0),0)),

('OTHER EXPENSES', FORMAT(COALESCE(varOEXP,0),0), FORMAT(COALESCE(varOEXPpreviousyear,0),0), FORMAT(COALESCE(varOEXPyoy,0),0)),

('--------------', '--------------','--------------','--------------'),

('INCOME TAX', FORMAT(COALESCE(varINCTAX,0),0), FORMAT(COALESCE(varINCTAXpreviousyear,0),0), FORMAT(COALESCE(varINCTAXyoy,0),0)),

('OTHER TAX', FORMAT(COALESCE(varOTHTAX,0),0), FORMAT(COALESCE(varOTHTAXpreviousyear,0),0), FORMAT(COALESCE(varOTHTAXyoy,0),0)),

('--------------', '--------------','--------------','--------------'),

('NET INCOME', FORMAT(COALESCE(varNI,0),0), FORMAT(COALESCE(varNIpreviousyear,0),0), FORMAT(COALESCE(varNIyoy,0),0)),

('NET INCOME %', FORMAT(COALESCE(varNIperc,0),0), FORMAT(COALESCE(varNIpercpreviousyear,0),0), FORMAT(COALESCE(varNIpercyoy,0),0))

;

END $$
DELIMITER ;	

CALL pl_statement(2016);
SELECT * FROM pl_statement;

/* CASHFLOW STATEMENT REPORT */
use new_schema;
/* Our first step was "cleaning" the messy database that we have. 
 For that, we decided to create a new table called tableCF, which is going to be our new databse. 
 We included all the necessary information for the balance sheet from 4 main tables: account, journal_entry, 
 journal_entry_line_item and statement_section.
 We created the table using the "with" function and then we left-joined all the "new" single tables.
 */
DROP PROCEDURE IF EXISTS cashflow_statement;

DELIMITER $$
CREATE PROCEDURE cashflow_statement(in calendaryear INT)
BEGIN                 
                
DROP TABLE IF EXISTS tableCF;

CREATE TABLE tableCF AS (

				 WITH acco AS (SELECT `account`, account_id, account_code, balance_sheet_order, balance_sheet_section_id
				 FROM `account`), 
                 
						ss AS (SELECT statement_section_id, statement_section_code, statement_section_order, is_balance_sheet_section
							FROM statement_section),
                            
						jeli AS (SELECT journal_entry_id, account_id, `description`, ifnull(debit, 0) AS debit, ifnull(credit, 0) AS credit
								FROM journal_entry_line_item),
                                
						je AS (SELECT journal_entry_id, journal_entry_code, journal_entry, entry_date, debit_credit_balanced, cancelled
							   FROM journal_entry)
                 
SELECT * 
FROM acco 
LEFT JOIN ss 
ON acco.balance_sheet_section_id = ss.statement_section_id
LEFT JOIN jeli 
USING (account_id)
LEFT JOIN je
USING (journal_entry_id)
);

/* After, we coded all the needed queries to get the balance of all the necessary accounts to build the report.
We filtered every query by the equivalent account code, by the entry date using the "YEAR" function 
and by including the non-cancelled values only. After, we built the query for the previous year as well.
Along the way, we used the "SET" function to build the formulas for the cash generated totals..
*/

-- NET INCOME: our group could not build the query to get the correct amount. 

-- CASH
SELECT 
    (SUM(IFNULL(credit, 0)) - SUM(IFNULL(debit, 0)))
INTO @cash FROM
    tableCF
WHERE
    account_code LIKE '101%'
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- BANK ACCOUNTS
SELECT 
    (SUM(IFNULL(credit, 0)) - SUM(IFNULL(debit, 0)))
INTO @bank_accounts FROM
    tableCF
WHERE
    account_code LIKE '102%'
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- ACCOUNT RECEIVABLES
SELECT 
    (SUM(IFNULL(credit, 0)) - SUM(IFNULL(debit, 0)))
INTO @acc_rec FROM
    tableCF
WHERE
    account_code LIKE '105%'
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- OTHER DEBITORS
SELECT 
    (SUM(IFNULL(credit, 0)) - SUM(IFNULL(debit, 0)))
INTO @o_deb FROM
    tableCF
WHERE
    account_code LIKE '107%'
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- EQUIPMENT TRANSPORTATION
SELECT 
    (SUM(IFNULL(debit, 0)) - SUM(IFNULL(credit, 0)))
INTO @eq_transp FROM
    tableCF
WHERE
    account_code LIKE '154%'
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- EQUIPMENT COMPUTERS
SELECT 
    (SUM(IFNULL(debit, 0)) - SUM(IFNULL(credit, 0)))
INTO @eq_comp FROM
    tableCF
WHERE
    account_code LIKE '156%'
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- EQUIPMENT FURNITURE
SELECT 
    (SUM(IFNULL(debit, 0)) - SUM(IFNULL(credit, 0)))
INTO @eq_furn FROM
    tableCF
WHERE
    account_code LIKE '155%'
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- DEPRECIATION
SELECT 
    (SUM(IFNULL(debit, 0)) - SUM(IFNULL(credit, 0)))
INTO @dep FROM
    tableCF
WHERE
    `account` LIKE '%depreciation%'
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- GUARANTEE DEPOSITS
SELECT 
    (SUM(IFNULL(credit, 0)) - SUM(IFNULL(debit, 0)))
INTO @g_dep FROM
    tableCF
WHERE
    account_code LIKE '184%'
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- ------------- changes in operating -----------------
-- INTERIM TAX PAYMENT
SELECT 
    (SUM(IFNULL(debit, 0)) - SUM(IFNULL(credit, 0)))
INTO @int_tax_paym FROM
    tableCF
WHERE
    account_code IN ('114%' , '113%')
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- TAXES TO BE CREDITED PRE PAID
SELECT 
    (SUM(IFNULL(debit, 0)) - SUM(IFNULL(credit, 0)))
INTO @tax_cred_pre FROM
    tableCF
WHERE
    account_code LIKE '118%'
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- TAXES TO BE CREDITED TO BE PAID
SELECT 
    (SUM(IFNULL(debit, 0)) - SUM(IFNULL(credit, 0)))
INTO @tax_cred_paid FROM
    tableCF
WHERE
    account_code LIKE '119%'
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- SUPPLIER PRE-PAYMENTS
SELECT 
    (SUM(IFNULL(debit, 0)) - SUM(IFNULL(credit, 0)))
INTO @sup_paym FROM
    tableCF
WHERE
    account_code LIKE '120%'
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- PAYABLES
SELECT 
    (SUM(IFNULL(debit, 0)) - SUM(IFNULL(credit, 0)))
INTO @payables FROM
    tableCF
WHERE
    account_code LIKE '201%'
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- ACCRUED EXPENSES
SELECT 
    (SUM(IFNULL(debit, 0)) - SUM(IFNULL(credit, 0)))
INTO @acc_exp FROM
    tableCF
WHERE
    account_code LIKE '205%'
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- ACCRUED TAXES - RECEIVED
SELECT 
    (SUM(IFNULL(debit, 0)) - SUM(IFNULL(credit, 0)))
INTO @acc_exp_rec FROM
    tableCF
WHERE
    account_code LIKE '208%'
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- ACCRUED TAXES - PENDING
SELECT 
    (SUM(IFNULL(debit, 0)) - SUM(IFNULL(credit, 0)))
INTO @acc_exp_pen FROM
    tableCF
WHERE
    account_code LIKE '209%'
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- ACCRUED TAXES - TO BE PAID
SELECT 
    (SUM(IFNULL(debit, 0)) - SUM(IFNULL(credit, 0)))
INTO @acc_exp_tbp FROM
    tableCF
WHERE
    account_code LIKE '213%'
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- DEFERRED INCOME
SELECT 
    (SUM(IFNULL(credit, 0)) - SUM(IFNULL(debit, 0)))
INTO @def_inc FROM
    tableCF
WHERE
    account_code LIKE '206%'
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0; 

-- Building the Cashflow Statement Report
/* To build the balance sheet report, we created a table with 5 columns and we inserted all the rows one-by-one, 
including the equivalent formulas. We cleaned the output results using the FORMAT and COALESCE functions. 
*/
DROP PROCEDURE  cashflow_report;

CREATE TABLE cashflow_report (
    category VARCHAR(50),
    subcategory VARCHAR(50),
    `current year` VARCHAR(20)
)
;

INSERT INTO cashflow_report(category, subcategory, `current year`)
VALUES  ('CASHFLOW STATEMENT', calendaryear,'in usd'),
		('--------------','--------------', '--------------'),
        ('OPERATING ACTIVITIES', ' ',' '),
		(' ', 'NET INCOME', varNI), 
		(' ', 'CASH', format(coalesce(@cash, 0), 0)),
		(' ', 'BANK ACCOUNTS', format(coalesce(@bank_accounts, 0), 0)),
		(' ', 'ACCOUNTS RECEIVABLE', format(coalesce(@acc_rec, 0), 0)),
		(' ', 'OTHER DEBITORS', format(coalesce(@o_deb, 0), 0)),
		(' ', 'EQUIPMENT TRANSPORTATION', format(coalesce(@eq_transp, 0), 0)),
		(' ', 'EQUIPMENT COMPUTERS', format(coalesce(@eq_comp, 0), 0)),
		(' ', 'EQUIPMENT FURNITURES', format(coalesce(@eq_furn, 0), 0)),
		(' ', 'DEPRECIATION', format(coalesce(@dep, 0), 0)),
		(' ', 'GUARANTEED DEPOSITS', format(coalesce(@g_dep, 0), 0)),
		(' ', 'EQUIPMENT FURNITURES', format(coalesce(@eq_furn, 0), 0)),
        ('CHANGES IN OPERATING ACTIVITIES', ' ',' '),
		(' ', 'INTERIM TAX PAYMENT', format(coalesce(@int_tax_paym, 0), 0)), 
		(' ', 'TAXES TO BE CREDITED - PRE PAID', format(coalesce(@tax_cred_pre, 0), 0)),
		(' ', 'TAXES TO BE CREDITED TO BE PAID', format(coalesce(@tax_cred_paid, 0), 0)),
		(' ', 'SUPPLIER PRE-PAYMENTS', format(coalesce(@sup_paym, 0), 0)),
		(' ', 'PAYABLES', format(coalesce(@payables, 0), 0)),
		(' ', 'ACCRUED EXPENSES', format(coalesce(@acc_exp, 0), 0)),
		(' ', 'ACCRUED TAXES - RECEIVED', format(coalesce(@acc_exp_rec, 0), 0)),
		(' ', 'ACCRUED TAXES - PENDING', format(coalesce(@acc_exp_pen, 0), 0)),
		(' ', 'ACCRUED TAXES - TO BE PAID', format(coalesce(@acc_exp_tbp, 0), 0)),
		(' ', 'DEFERRED INCOME', format(coalesce(@def_inc, 0), 0)),
		('CASH GENERATED BY OP ACTIVITIES', ' ',@cash_gen_op_act),
        ('INVESTING AND FINANCING ACTIVITIES', ' ',' '),
		(' ', 'OWNERS EQUITY', ' '),
        (' ', 'RETAINED EARNINGS', ' '),
		('CASH ENDING BALANCE', ' ', @cash_gen_op_act)
        ;
        


END $$
DELIMITER ;


CALL cashflow_statement(2016);
SELECT * FROM cashflow_report;




