-- This file provides an SQL based solution to the following database
-- business requirements for the PropertyManagementDB database

USE PropertyManagementDB;

 /*
     Business Requirements #1
     ----------------------------------------------------
     Purpose: Role-Based Access Control with Expiry Dates
     
     Description: The system must implement a role-based access control (RBAC) 
                  mechanism that restricts user access to specific features 
                  based on their assigned roles, which for this system will be Admin, Owner, and Guest.
                  Admin is for support roles such as property managers, Owner is for the users who actually own the property,
                  and Guest is for users who don't have access to view most information.
                  Each role assignment shall have an expiration date, after which the user's access 
                  to the associated features will be automatically revoked. 
     
     Challenge:   Roles need to be checked both at log in for expiration and for any arbitrary task which may not be programmed yet. 
     There needs to be a way where any query may use this check.
     
     Implementation Plan:
        1. Create a stored procedure to assign a role to a user with an expiration date.
        2. Create a trigger to check for expired roles when a user logs in or attempts to perform a query. If expired, change the
        role to Guest (3). If Admin(2), limit all queries for now. If Owner(1), allow the queries.
        3. Create a function to check an active role.
        4. Create a procedure to manually refresh an expiration date or assign a new role to a user.
  */
  
DELIMITER $$
  
-- 1
DROP PROCEDURE IF EXISTS AssignRole;
CREATE PROCEDURE AssignRole(IN in_user_id INT, IN in_role_id INT, IN in_expires DATE)
BEGIN
    -- Update the RegisteredUsers table with the new role and expiration date
    UPDATE RegisteredUsers 
    SET role_id = in_role_id
    WHERE tracking_id = in_user_id;

    -- Update the expiration date in the Roles table
    UPDATE Roles
    SET expires = in_expires
    WHERE role_id = in_role_id;
END$$

-- 2
DELIMITER $$
DROP PROCEDURE IF EXISTS CheckBeforeQuery;
CREATE PROCEDURE CheckBeforeQuery(IN in_user_id INT, IN in_query TEXT)

BEGIN
	DECLARE today DATE;
    DECLARE exp_date DATE;
    DECLARE user_role_id INT;
    SET today = CURDATE();
    
    -- Get the user's role and expiration date
    SELECT RU.role_id, R.expires
    INTO user_role_id, exp_date
    FROM RegisteredUsers RU
    JOIN Roles R ON RU.role_id = R.role_id
    WHERE RU.tracking_id = in_user_id;
    
    -- If the role is expired, change the user to Guest
    IF exp_date < today THEN
		UPDATE RegisteredUsers
		SET role_id = 3 -- 3 is the enum value for guest
		WHERE tracking_id = in_user_id;
        SET user_role_id = 3; -- Is this updating in db?
    END IF;
    
    -- Owner can execute any query
    IF user_role_id = 1 THEN
    SET @prompt = in_query; -- prefixed with @ means not local
    PREPARE exec FROM @prompt; -- Converts a SQL string into an executable statement
    EXECUTE exec; -- Runs the prepared SQL statement
    DEALLOCATE PREPARE exec; -- Cleans up memory
        ELSEIF user_role_id = 2 THEN
        -- Admin cannot execute queries for now
        SIGNAL SQLSTATE '45000' -- Generic "user-defined error" code
        SET MESSAGE_TEXT = 'Admins may not execute this query.';
    ELSE
        -- Guests or invalid roles cannot execute queries
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Guests may not execute this query.';
    END IF;
    END$$
    
-- 3 
DROP PROCEDURE IF EXISTS RefreshRole;
CREATE PROCEDURE RefreshRole(IN in_user_id INT, IN in_role_id INT)
BEGIN

	-- Update the RegisteredUsers table first to make sure the right role is set
	UPDATE RegisteredUsers
    SET role_id = in_role_id
    WHERE tracking_id = in_user_id;
    
    -- Then update the expiration date in the Roles table
    UPDATE Roles
    SET expires = DATE_ADD(CURDATE(), INTERVAL 1 YEAR)
    WHERE role_id = in_role_id;
    END$$
    
    DELIMITER ;
    
-- Test
    CALL AssignRole(1, 1, '2025-12-10');
    CALL CheckBeforeQuery(1,'SELECT * FROM Properties');
    CALL RefreshRole(1, 3); -- Change user 1's role to Guest
    
-- Display results
	SELECT RU.full_name, RU.role_id
    FROM RegisteredUsers RU
    LEFT JOIN Roles R ON RU.role_id = R.role_id;
    
    
/*
    Business Requirement #2:
	----------------------------------------------------
	Purpose: Assess best and worst performers in an investment portfolio
     
	Description: The system must be able to order properties by performance according to cash flow and after-repair-value with display of
	main pertinent information.
     
	Challenge:   The challenge is running calculations of current data to generate dynamic calculations of the cash flow for each property.
     
	Assumptions: All of the available information is current.
     
	Implementation Plan:
		1. Create a CTE to calculate cash flow for each property
        2. Select all columns to be displayed, including using the CTE to display cash flow for each property.
*/

-- 1

CREATE OR REPLACE VIEW PortfolioPerformance AS
WITH CashFlowCTE AS (
    SELECT 
        pp.property_id,
        pp.property_rent,
        IFNULL(m.monthly_payment, 0) AS monthly_payment,
        IFNULL(prop.monthly_capex, 0) AS monthly_capex,
        (pp.property_rent - (IFNULL(m.monthly_payment, 0) + IFNULL(prop.monthly_capex, 0))) AS cash_flow
    FROM PortfolioProperties pp
    INNER JOIN Properties prop ON pp.property_id = prop.property_id
    LEFT JOIN Mortgages m ON prop.property_id = m.property_id
)
-- 2
SELECT 
    ru.tracking_id AS User_ID,
    ru.email,
    p.portfolio_id AS Portfolio_ID,
    pp.property_id AS Property_ID,
    CONCAT(a.number, ' ', a.street, ', ', a.city, ', ', a.state_province, ', ', a.country) AS Address,
    pp.property_rent AS Rental_Income,
    m.monthly_payment AS Mortgage,
    prop.monthly_capex AS Capital_Expenditures,
    cfte.cash_flow 
    ph.purchase_price AS Purchase_Price,
    prop.target_arv AS ARV
FROM RegisteredUsers ru
INNER JOIN UserPortfolios up ON ru.tracking_id = up.user_id
INNER JOIN Portfolios p ON up.portfolio_id = p.portfolio_id
INNER JOIN PortfolioProperties pp ON p.portfolio_id = pp.portfolio_id
INNER JOIN Properties prop ON pp.property_id = prop.property_id
INNER JOIN PropertyHistories ph ON prop.property_id = ph.property_id
LEFT JOIN Mortgages m ON prop.property_id = m.property_id
LEFT JOIN Addresses a ON prop.address_id = a.address_id
LEFT JOIN CashFlowCTE cfte ON pp.property_id = cfte.property_id

DELIMITER ; 

-- Testing
SELECT *
FROM PortfolioPerformance
WHERE User_ID = 2 -- Only used for demo purposes. Python will handle identity + filtering.
ORDER BY cash_flow ASC;

/*
    Business Requirement #3:
    ----------------------------------------------------
    Purpose: Display all of a registered user's tenants associated with their portfolio, and organize them by highest past due balance.

    Description: The system must be able to list tenants who are associated with properties within a specific portfolio owned or managed by a registered user. The tenant information should include details about their assigned units, property addresses, and past due balances.

    Challenge: The challenge is ensuring that the query dynamically filters tenants by navigating through the right associative tables.

    Assumptions: The data for registered users, portfolios, properties, and tenants is current and correctly linked in the system.

    Implementation Plan:
        1. Join the relevant tables (`RegisteredUsers`, `UserPortfolios`, `Portfolios`, `PortfolioProperties`, `Properties`, `Units`, `UnitTenants`, and `Tenants`) to gather the necessary tenant and property details.
        2. Filter the results by the `tracking_id` of the specific registered user to only return tenants for their portfolio.
        3. Include key tenant information such as tenant name, property address, unit ID, and past due balance.
        4. Sort the results by past due balance to highlight tenants with the most overdue amounts.
*/
CREATE OR REPLACE VIEW ViewTenants AS
SELECT 
	ru.tracking_id AS user_id,
    t.tenant_id,
    t.full_name AS tenant_name,
	ut.unit_id,
    a.numbered_street AS property_address,
    t.past_due_balance
FROM 
    RegisteredUsers ru
JOIN 
    UserPortfolios up ON ru.tracking_id = up.user_id
JOIN 
    Portfolios pf ON up.portfolio_id = pf.portfolio_id
JOIN 
    PortfolioProperties pp ON pf.portfolio_id = pp.portfolio_id
JOIN 
    Properties p ON pp.property_id = p.property_id
JOIN 
    Units u ON p.property_id = u.property_id
JOIN 
    UnitTenants ut ON u.unit_id = ut.unit_id
JOIN 
    Tenants t ON ut.tenant_id = t.tenant_id
JOIN 
    Addresses a ON p.address_id = a.address_id
    
    DELIMITER ;
    -- Testing
    SELECT *
    FROM ViewTenants
    WHERE user_id = 1
    ORDER BY t.past_due_balance DESC;


/*
    Business Requirement #4:
    ----------------------------------------------------
    Purpose: Display all of a registered user's mortgages associated with their portfolio and dates, so a user can easily see if they may refinance or not.

    Description: The system must be able to display loan balances and last purchase price to give the user an idea of how much equity they have
    so they may evaluate if they should refinance or make other decisions.

    Challenge: The challenge is displaying the right information so the user may make informed investment decisions.

    Assumptions: The data is all current and the purchase price is a decent evaluation model for equity without accounting for current appraisals.

    Implementation Plan:
        1. Join the correct tables to get mortgage infos, addresses, and purchase prices.
        2. Display a total principal balance and purchase price at the bottom using UNION
*/

CREATE OR REPLACE VIEW ViewMortgages AS
-- 1
SELECT
	ru.tracking_id AS user_id,
    m.tracking_id AS mortgage_id,
    m.lender_name,
    m.principal_balance,
    m.interest_rate,
    m.monthly_payment,
    m.start_date,
    m.end_date,
    ph.purchase_price,
    CONCAT(a.number, ' ', a.street, ', ', a.city, ', ', a.state_province, ', ', a.country) AS property_address,
    ru.full_name AS registered_user
FROM Mortgages m
JOIN Properties p ON m.property_id = p.property_id
JOIN PropertyHistories ph ON ph.property_id = p.property_id
JOIN PortfolioProperties pp ON pp.property_id = p.property_id
JOIN Portfolios pf ON pf.portfolio_id = pp.portfolio_id
JOIN UserPortfolios up ON up.portfolio_id = pf.portfolio_id
JOIN RegisteredUsers ru ON ru.tracking_id = up.tracking_id
JOIN Addresses a ON p.address_id = a.address_id


-- 2
UNION ALL

SELECT
	ru.tracking_id AS user_id,
    NULL AS mortgage_id,
    'Total' AS lender_name,
    SUM(m.principal_balance) AS total_principal_balance,
    NULL AS interest_rate,
    SUM(m.monthly_payment) AS total_monthly_payment,
    NULL AS start_date,
    NULL AS end_date,
    SUM(ph.purchase_price) as purchase_price,
    NULL AS property_address,
    ru.full_name AS registered_user
FROM Mortgages m
JOIN Properties p ON m.property_id = p.property_id
JOIN PropertyHistories ph ON ph.property_id = p.property_id
JOIN PortfolioProperties pp ON pp.property_id = p.property_id
JOIN Portfolios pf ON pf.portfolio_id = pp.portfolio_id
JOIN UserPortfolios up ON up.portfolio_id = pf.portfolio_id
JOIN RegisteredUsers ru ON ru.tracking_id = up.tracking_id
GROUP BY ru.tracking_id;


DELIMITER ;

-- Testing
SELECT * 
FROM ViewMortgages
WHERE user_id = 1 OR user_id IS NULL
ORDER BY mortgage_id IS NULL, start_date ASC;

/*
    Business Requirement #5:
    ----------------------------------------------------
    Purpose: Display all ongoing projects in a user's portfolio and the contractor assigned to them.

    Description: Display all ongoing projects in a user's portfolio and the contractor assigned to them.

    Challenge: The challenge is displaying the right information so the user may understand all of their projects at a glance.

    Assumptions: The data is all current.
    

    Implementation Plan:
        1. Display property addresses associated with the portfolio of a specific registereduser by using the portfolioproperties associative table,
    display each property's projectinfo, if it is in progress, the title, and description of the project, and use the projectcontractors 
    table to display the company name, full name, and services of each corresponding contractor. 
*/

CREATE OR REPLACE VIEW CurrentProjects AS
SELECT
	ru.tracking_id AS user_id,
    a.numbered_street,
    a.city,
    pi.project_title AS project,
    pi.in_progress,
    pi.project_description,
    c.company_name AS contractor_company,
    c.full_name AS contractor,
    c.services
    
FROM RegisteredUsers ru
JOIN UserPortfolios up on ru.tracking_id = up.user_id
JOIN Portfolios p on up.portfolio_id = p.portfolio_id
JOIN PortfolioProperties pp on p.portfolio_id = pp.portfolio_id
JOIN Properties prop on pp.property_id = prop.property_id
JOIN ProjectInfos pi on prop.property_id = pi.property_id
JOIN ProjectContractors pc on pc.project_id = pi.project_id
JOIN Contractors c on pc.contractor_id = c.tracking_id
JOIN Addresses a on prop.address_id = a.address_id

DELIMITER ;
-- Testing
SELECT *
FROM CurrentProjects
WHERE user_id = 1
