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
DELIMITER $$
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
    CALL AssignRole(1, 1, '2030-12-10');
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
    cfte.cash_flow, 
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

/*
Business Requirement #6:
----------------------------------------------------
Purpose: Assign a complete set of sample data for new users to begin testing the program.

Description: Insert sample data into each entity corresponding with the Portfolio of the calling RegisteredUser.

Challenge: Connecting all tables to the same portfolio, and ensuring consistency in the data. Also important is to ensure 
that it can only be called once to prevent excessive querying or DOS attacks.

Assumptions: The calling method provides the tracking_id of the calling RegisteredUser.

Implementation plan: 
1. Drop the procedure if it exists. Create it and pass in the caller's user tracking_id.
2. Wrap the procedure in START and COMMIT with an exit exception to ROLLBACK, so we don't have partial data errors.
3. Get the user's portfolio, or create one if it doesn't exist.
4. Begin inserting sample properties into Portfolio.
5. Follow the EER to implement corresponding data in other entities branching off from Portfolio for tracking
and consistency.
6. COMMIT the changes.
*/

DELIMITER $$

DROP PROCEDURE IF EXISTS CreateSampleUserData $$

CREATE PROCEDURE CreateSampleUserData(IN in_user_id BIGINT)
BEGIN
    DECLARE v_portfolio_id INT;

    -- Addresses
    DECLARE addr0 INT; DECLARE addr1 INT; DECLARE addr2 INT; DECLARE addr3 INT; DECLARE addr4 INT; DECLARE addr5 INT;

    -- Properties
    DECLARE prop0 INT; DECLARE prop1 INT; DECLARE prop2 INT; DECLARE prop3 INT; DECLARE prop4 INT; DECLARE prop5 INT;

    -- ProjectInfos
    DECLARE proj0 INT; DECLARE proj1 INT; DECLARE proj2 INT; DECLARE proj3 INT; DECLARE proj4 INT; DECLARE proj5 INT;

    -- Contractors
    DECLARE cont0 INT; DECLARE cont1 INT; DECLARE cont2 INT; DECLARE cont3 INT; DECLARE cont4 INT; DECLARE cont5 INT;

    -- PropertyHistories
    DECLARE hist0 INT; DECLARE hist1 INT; DECLARE hist2 INT; DECLARE hist3 INT; DECLARE hist4 INT; DECLARE hist5 INT;

    -- Units
    DECLARE unit0 INT; DECLARE unit1 INT; DECLARE unit2 INT; DECLARE unit3 INT; DECLARE unit4 INT; DECLARE unit5 INT;

    -- LeaseAgreements
    DECLARE lease0 INT; DECLARE lease1 INT; DECLARE lease2 INT; DECLARE lease3 INT; DECLARE lease4 INT; DECLARE lease5 INT;

    -- Tenants
    DECLARE tenant0 INT; DECLARE tenant1 INT; DECLARE tenant2 INT; DECLARE tenant3 INT; DECLARE tenant4 INT; DECLARE tenant5 INT;

    -- Exit handler
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

        START TRANSACTION;

        -- Get or create portfolio
        SELECT portfolio_id INTO v_portfolio_id
        FROM UserPortfolios
        WHERE user_id = in_user_id
        LIMIT 1;

        IF v_portfolio_id IS NULL THEN
            INSERT INTO Portfolios(num_properties, last_appraised_val) VALUES (0,0);
            SET v_portfolio_id = LAST_INSERT_ID();
            INSERT INTO UserPortfolios(user_id, portfolio_id, last_appraised_val)
            VALUES (in_user_id, v_portfolio_id, 0);
        END IF;

        -- Insert Addresses
        INSERT INTO Addresses(country,state_province,city,street,number)
        VALUES ('USA','California','Los Angeles','Sunset Blvd',101);
        SET addr0 = LAST_INSERT_ID();

        INSERT INTO Addresses(country,state_province,city,street,number)
        VALUES ('USA','California','Los Angeles','Hollywood Blvd',202);
        SET addr1 = LAST_INSERT_ID();

        INSERT INTO Addresses(country,state_province,city,street,number)
        VALUES ('USA','New York','New York City','5th Ave',303);
        SET addr2 = LAST_INSERT_ID();

        INSERT INTO Addresses(country,state_province,city,street,number)
        VALUES ('USA','Florida','Miami','Ocean Dr',404);
        SET addr3 = LAST_INSERT_ID();

        INSERT INTO Addresses(country,state_province,city,street,number)
        VALUES ('USA','Texas','Houston','Main St',505);
        SET addr4 = LAST_INSERT_ID();

        INSERT INTO Addresses(country,state_province,city,street,number)
        VALUES ('USA','Illinois','Chicago','Lake Shore Dr',606);
        SET addr5 = LAST_INSERT_ID();

        -- Insert Properties
        INSERT INTO Properties(total_rent, monthly_capex, bedroom_count, bathroom_count, sqft, lot_size, target_arv, address_id)
        VALUES (5000,500,3,2,1800,5000,1000000,addr0);
        SET prop0 = LAST_INSERT_ID();

        INSERT INTO Properties(total_rent, monthly_capex, bedroom_count, bathroom_count, sqft, lot_size, target_arv, address_id)
        VALUES (2500,250,2,1,900,2000,500000,addr1);
        SET prop1 = LAST_INSERT_ID();

        INSERT INTO Properties(total_rent, monthly_capex, bedroom_count, bathroom_count, sqft, lot_size, target_arv, address_id)
        VALUES (5500,550,3,2,1500,4000,1500000,addr2);
        SET prop2 = LAST_INSERT_ID();

        INSERT INTO Properties(total_rent, monthly_capex, bedroom_count, bathroom_count, sqft, lot_size, target_arv, address_id)
        VALUES (1000,100,1,1,1200,1200,300000,addr3);
        SET prop3 = LAST_INSERT_ID();

        INSERT INTO Properties(total_rent, monthly_capex, bedroom_count, bathroom_count, sqft, lot_size, target_arv, address_id)
        VALUES (1100,110,1,1,1300,1300,400000,addr4);
        SET prop4 = LAST_INSERT_ID();

        INSERT INTO Properties(total_rent, monthly_capex, bedroom_count, bathroom_count, sqft, lot_size, target_arv, address_id)
        VALUES (5500,550,4,2,2000,6000,1000000,addr5);
        SET prop5 = LAST_INSERT_ID();

        -- PortfolioProperties
        INSERT INTO PortfolioProperties(portfolio_id, property_id, property_rent)
        VALUES 
            (v_portfolio_id, prop0, 5000),
            (v_portfolio_id, prop1, 2500),
            (v_portfolio_id, prop2, 5500),
            (v_portfolio_id, prop3, 1000),
            (v_portfolio_id, prop4, 1100),
            (v_portfolio_id, prop5, 5500);

        -- TaxRecords
        INSERT INTO TaxRecords(property_id,payment_date,due_date,amount_paid,year)
        VALUES
            (prop0,'2024-03-01','2024-03-15',5000,2024),
            (prop1,'2024-04-01','2024-04-15',2500,2024),
            (prop2,'2024-05-01','2024-05-15',5500,2024),
            (prop3,'2024-06-01','2024-06-15',1000,2024),
            (prop4,'2024-07-01','2024-07-15',1100,2024),
            (prop5,'2024-08-01','2024-08-15',5500,2024);

        -- Mortgages
        INSERT INTO Mortgages(lender_name,principal_balance,interest_rate,monthly_payment,start_date,end_date,property_id,terms)
        VALUES
            ('Bank A',400000,3.5,1800,'2000-01-01','2030-01-01',prop0,'30-year fixed'),
            ('Bank B',200000,4.0,1200,'2001-02-01','2026-02-01',prop1,'25-year fixed'),
            ('Bank C',500000,3.8,2400,'2024-03-01','2054-03-01',prop2,'30-year fixed'),
            ('Bank D',150000,3.6,800,'2005-04-01','2025-04-01',prop3,'20-year fixed'),
            ('Bank E',250000,3.9,1300,'2010-05-01','2035-05-01',prop4,'25-year fixed'),
            ('Bank F',600000,3.7,2800,'2007-06-01','2037-06-01',prop5,'30-year fixed');

        -- InsurancePolicies
        INSERT INTO InsurancePolicies(policy_number,provider,monthly_cost,start_date,end_date,property_id)
        VALUES
            (101,'Insurance Co A',150,'2024-01-01','2025-01-01',prop0),
            (102,'Insurance Co B',120,'2024-02-01','2025-02-01',prop1),
            (103,'Insurance Co C',180,'2024-03-01','2025-03-01',prop2),
            (104,'Insurance Co D',100,'2024-04-01','2025-04-01',prop3),
            (105,'Insurance Co E',110,'2024-05-01','2025-05-01',prop4),
            (106,'Insurance Co F',160,'2024-06-01','2025-06-01',prop5);

        -- ProjectInfos
        INSERT INTO ProjectInfos(in_progress,project_title,project_description,ProjectInfoscol,property_id)
        VALUES
            (1,'Kitchen Renovation','Renovating the kitchen for better functionality.','Additional Notes',prop0),
            (0,'Bathroom Remodel','Updating the bathroom with new fixtures and tiles.','Details here',prop1),
            (1,'Roof Repair','Fixing leaks and ensuring the roof is stable.','Roof inspection due soon',prop2),
            (0,'Landscaping','Landscaping the front yard to increase curb appeal.','Final design pending',prop3),
            (1,'HVAC System Upgrade','Installing new energy-efficient HVAC system.','Work in progress',prop4),
            (0,'Foundation Inspection','Inspecting the foundation for any structural issues.','Scheduled for next month',prop5);

        SET proj0 = LAST_INSERT_ID(); -- we'll only need base ID for incremental inserts like ProjectUpdates
        SET proj1 = proj0 + 1; SET proj2 = proj0 + 2; SET proj3 = proj0 + 3; SET proj4 = proj0 + 4; SET proj5 = proj0 + 5;

        -- ProjectUpdates
        INSERT INTO ProjectUpdates(project_id,updates,date)
        VALUES
            (proj0,'Started demolition of old cabinets and countertops.','2024-01-10'),
            (proj1,'Demolition complete, tiles selected for new bathroom.','2024-02-20'),
            (proj2,'Roof inspection complete, materials ordered for repair.','2024-03-05'),
            (proj3,'Landscaping team has started work on the front yard.','2024-04-01'),
            (proj4,'HVAC system installation started, ducts being replaced.','2024-05-10'),
            (proj5,'Foundation inspection scheduled for next week.','2024-06-15');

        -- Contractors
        INSERT INTO Contractors(company_name,services,first_name,last_name,user_id)
        VALUES
            ('Construction Co A','General contracting, kitchen remodel','John','Doe', in_user_id),
            ('Construction Co B','Bathroom remodeling, plumbing','Jane','Smith', in_user_id),
            ('Roofing Co C','Roof repairs, maintenance','Michael','Johnson', in_user_id),
            ('Landscaping Co D','Landscaping, yard design','Emily','Brown', in_user_id),
            ('HVAC Co E','HVAC installation, maintenance','David','White', in_user_id),
            ('Foundation Co F','Foundation inspection and repair','Sarah','Davis', in_user_id);

        SET cont0 = LAST_INSERT_ID(); SET cont1 = cont0 + 1; SET cont2 = cont0 + 2;
        SET cont3 = cont0 + 3; SET cont4 = cont0 + 4; SET cont5 = cont0 + 5;

        -- ProjectContractors
        INSERT INTO ProjectContractors(project_id,contractor_id,services)
        VALUES
            (proj0,cont0,'General contracting, kitchen remodel'),
            (proj1,cont1,'Bathroom remodeling, plumbing'),
            (proj2,cont2,'Roof repairs, maintenance'),
            (proj3,cont3,'Landscaping, yard design'),
            (proj4,cont4,'HVAC installation, maintenance'),
            (proj5,cont5,'Foundation inspection and repair');

        -- PropertyHistories
        INSERT INTO PropertyHistories(purchase_price,maintenance_notes,last_appraised_val,purchase_date,property_id)
        VALUES
            (800000,'Kitchen remodel completed in 2024',800000,'2023-05-01',prop0),
            (1700000,'Bathroom renovation started in 2024',1700000,'2023-06-01',prop1),
            (500000,'Roof repairs scheduled for 2024',500000,'2023-07-01',prop2),
            (700000,'Landscaping improvements in progress',700000,'2023-08-01',prop3),
            (600000,'HVAC system upgrade in progress',600000,'2023-09-01',prop4),
            (650000,'Foundation inspection pending',650000,'2023-10-01',prop5);

        SET hist0 = LAST_INSERT_ID(); SET hist1 = hist0 + 1; SET hist2 = hist0 + 2;
        SET hist3 = hist0 + 3; SET hist4 = hist0 + 4; SET hist5 = hist0 + 5;

        -- ExpenseHistories
        INSERT INTO ExpenseHistories(date,cost,label,history_id)
        VALUES
            ('2024-01-01',5000,'Kitchen remodel',hist0),
            ('2024-02-01',2500,'Bathroom renovation',hist1),
            ('2024-03-01',3000,'Roof repairs',hist2),
            ('2024-04-01',1500,'Landscaping',hist3),
            ('2024-05-01',2000,'HVAC upgrade',hist4),
            ('2024-06-01',2500,'Foundation inspection',hist5);

        -- InspectionRecords
        INSERT INTO InspectionRecords(notes,inspector_firstname,inspector_lastname,history_id)
        VALUES
            ('Kitchen remodel completed successfully','James','Taylor',hist0),
            ('Bathroom renovation is 50% complete','Linda','Martinez',hist1),
            ('Roof repairs scheduled for March 2024','Robert','Lee',hist2),
            ('Landscaping improvements started','Patricia','Harris',hist3),
            ('HVAC system upgrade in progress','William','Clark',hist4),
            ('Foundation inspection results pending','Elizabeth','Lewis',hist5);

        -- Units
        INSERT INTO Units(property_id,bedroom_count,bathroom_count,rent,vacant,address_id)
        VALUES
            (prop0,3,2,5000,1,addr0),
            (prop1,2,1,2500,0,addr1),
            (prop2,3,2,5500,0,addr2),
            (prop3,1,1,1000,1,addr3),
            (prop4,1,1,1100,0,addr4),
            (prop5,4,2,5500,1,addr5);

        SET unit0 = LAST_INSERT_ID(); SET unit1 = unit0 + 1; SET unit2 = unit0 + 2;
        SET unit3 = unit0 + 3; SET unit4 = unit0 + 4; SET unit5 = unit0 + 5;

        -- LeaseAgreements
        INSERT INTO LeaseAgreements(rent,start_date,end_date,terms,property_id)
        VALUES
            (5000,'2024-01-01','2025-01-01','12-month lease',prop0),
            (2500,'2024-02-01','2025-02-01','12-month lease',prop1),
            (5500,'2024-03-01','2025-03-01','12-month lease',prop2),
            (1000,'2024-04-01','2025-04-01','12-month lease',prop3),
            (1100,'2024-05-01','2025-05-01','12-month lease',prop4),
            (5500,'2024-06-01','2025-06-01','12-month lease',prop5);

        SET lease0 = LAST_INSERT_ID(); SET lease1 = lease0 + 1; SET lease2 = lease0 + 2;
        SET lease3 = lease0 + 3; SET lease4 = lease0 + 4; SET lease5 = lease0 + 5;

        -- Tenants
        INSERT INTO Tenants(notes,first_name,last_name,lease_id,past_due_balance)
        VALUES
            ('Tenant is a reliable renter.','John','Doe',lease0,0),
            ('Tenant moved in early.','Jane','Smith',lease1,0),
            ('Tenant is late with payments.','Alice','Johnson',lease2,11000),
            ('Tenant is renting a small studio.','Michael','Williams',lease3,0),
            ('Tenant has a family of three.','Emily','Brown',lease4,0),
            ('Tenant requested an extension.','Daniel','Davis',lease5,5500);

        SET tenant0 = LAST_INSERT_ID(); SET tenant1 = tenant0 + 1; SET tenant2 = tenant0 + 2;
        SET tenant3 = tenant0 + 3; SET tenant4 = tenant0 + 4; SET tenant5 = tenant0 + 5;

        -- PaymentHistories
        INSERT INTO PaymentHistories(amount,paid_date,due_date,unit_id,tenant_id)
        VALUES
            (5000,'2024-11-29','2024-12-01',unit0,tenant0),
            (2500,'2024-12-01','2024-12-01',unit1,tenant1),
            (5500,'2024-10-01','2024-12-01',unit2,tenant2),
            (1000,'2024-12-01','2024-12-01',unit3,tenant3),
            (1100,'2024-11-29','2024-12-01',unit4,tenant4),
            (5500,'2024-11-01','2024-12-01',unit5,tenant5);

        -- UnitTenants
        INSERT INTO UnitTenants(unit_id,tenant_id,tenant_name,address_id,lease_id)
        VALUES
            (unit0,tenant0,'John Doe',addr0,lease0),
            (unit1,tenant1,'Jane Smith',addr1,lease1),
            (unit2,tenant2,'Alice Johnson',addr2,lease2),
            (unit3,tenant3,'Michael Williams',addr3,lease3),
            (unit4,tenant4,'Emily Brown',addr4,lease4),
            (unit5,tenant5,'Daniel Davis',addr5,lease5);

        COMMIT;
END $$

DELIMITER ;

DELIMITER $$

DROP PROCEDURE IF EXISTS ResetUserData $$

CREATE PROCEDURE ResetUserData(IN in_user_id BIGINT)
BEGIN
-- Cleanup all sample data for a specific user
SET @user_id = in_user_id;

-- 1️ Delete PaymentHistories
DELETE ph FROM PaymentHistories ph
JOIN Units u ON ph.unit_id = u.unit_id
JOIN PortfolioProperties pp ON u.property_id = pp.property_id
JOIN UserPortfolios up ON pp.portfolio_id = up.portfolio_id
WHERE up.user_id = @user_id;

-- 2️ Delete UnitTenants
DELETE ut FROM UnitTenants ut
JOIN Units u ON ut.unit_id = u.unit_id
JOIN PortfolioProperties pp ON u.property_id = pp.property_id
JOIN UserPortfolios up ON pp.portfolio_id = up.portfolio_id
WHERE up.user_id = @user_id;

-- Delete Tenants **before** LeaseAgreements
DELETE t FROM Tenants t
JOIN LeaseAgreements la ON t.lease_id = la.lease_id
JOIN Properties p ON la.property_id = p.property_id
JOIN PortfolioProperties pp ON p.property_id = pp.property_id
JOIN UserPortfolios up ON pp.portfolio_id = up.portfolio_id
WHERE up.user_id = @user_id;

-- ️3 Delete LeaseAgreements
DELETE la FROM LeaseAgreements la
JOIN Properties p ON la.property_id = p.property_id
JOIN PortfolioProperties pp ON p.property_id = pp.property_id
JOIN UserPortfolios up ON pp.portfolio_id = up.portfolio_id
WHERE up.user_id = @user_id;

-- 5 Delete ExpenseHistories
DELETE eh FROM ExpenseHistories eh
JOIN PropertyHistories ph ON eh.history_id = ph.history_id
JOIN PortfolioProperties pp ON ph.property_id = pp.property_id
JOIN UserPortfolios up ON pp.portfolio_id = up.portfolio_id
WHERE up.user_id = @user_id;

-- 6️ Delete InspectionRecords
DELETE ir FROM InspectionRecords ir
JOIN PropertyHistories ph ON ir.history_id = ph.history_id
JOIN PortfolioProperties pp ON ph.property_id = pp.property_id
JOIN UserPortfolios up ON pp.portfolio_id = up.portfolio_id
WHERE up.user_id = @user_id;

-- 7️ Delete ProjectContractors
DELETE pc FROM ProjectContractors pc
JOIN ProjectInfos pi ON pc.project_id = pi.project_id
JOIN PortfolioProperties pp ON pi.property_id = pp.property_id
JOIN UserPortfolios up ON pp.portfolio_id = up.portfolio_id
WHERE up.user_id = @user_id;

-- 8️ Delete ProjectUpdates
DELETE pu FROM ProjectUpdates pu
JOIN ProjectInfos pi ON pu.project_id = pi.project_id
JOIN PortfolioProperties pp ON pi.property_id = pp.property_id
JOIN UserPortfolios up ON pp.portfolio_id = up.portfolio_id
WHERE up.user_id = @user_id;

-- 9️ Delete InsurancePolicies
DELETE ip FROM InsurancePolicies ip
JOIN Properties p ON ip.property_id = p.property_id
JOIN PortfolioProperties pp ON p.property_id = pp.property_id
JOIN UserPortfolios up ON pp.portfolio_id = up.portfolio_id
WHERE up.user_id = @user_id;

-- 10 Delete ProjectInfos
DELETE pi FROM ProjectInfos pi
JOIN PortfolioProperties pp ON pi.property_id = pp.property_id
JOIN UserPortfolios up ON pp.portfolio_id = up.portfolio_id
WHERE up.user_id = @user_id;

-- 11 Delete Contractors
DELETE c
FROM Contractors c
WHERE c.user_id = @user_id;


-- 12️ Delete PropertyHistories
DELETE ph FROM PropertyHistories ph
JOIN PortfolioProperties pp ON ph.property_id = pp.property_id
JOIN UserPortfolios up ON pp.portfolio_id = up.portfolio_id
WHERE up.user_id = @user_id;

-- 13 Delete Units
DELETE u FROM Units u
JOIN PortfolioProperties pp ON u.property_id = pp.property_id
JOIN UserPortfolios up ON pp.portfolio_id = up.portfolio_id
WHERE up.user_id = @user_id;

-- 14️ Delete PortfolioProperties
DELETE pp FROM PortfolioProperties pp
JOIN UserPortfolios up ON pp.portfolio_id = up.portfolio_id
WHERE up.user_id = @user_id;

# For the below operations, SQL requires turning off safemode. Also, these delete global orphan data rather than user specific.
# Better to create separate operation for clearing orphans.
-- 15️ Delete Properties that are not in PortfolioProperties
-- DELETE p
-- FROM Properties p
-- LEFT JOIN PortfolioProperties pp
--     ON p.property_id = pp.property_id
-- WHERE pp.property_id IS NULL;


-- 16️ Delete Addresses that are not referenced by any Property
-- DELETE a
-- FROM Addresses a
-- LEFT JOIN Properties p
--     ON a.address_id = p.address_id
-- WHERE p.address_id IS NULL;

-- 17️ Delete TaxRecords whose property no longer exists
-- DELETE tr
-- FROM TaxRecords tr
-- LEFT JOIN Properties pRegisteredUsers
--     ON tr.property_id = p.property_id
-- WHERE p.property_id IS NULL;

-- 18️ Delete Mortgages whose property no longer exists
-- DELETE m
-- FROM Mortgages m
-- LEFT JOIN Properties p
--     ON m.property_id = p.property_id
-- WHERE p.property_id IS NULL;
END $$
