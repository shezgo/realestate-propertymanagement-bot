-- This file is used to insert sample data to populate the PropertyManagementDB database
USE PropertyManagementDB;

INSERT INTO `Roles` (role_id, role_type) 
VALUES
(1, 'Owner'),
(2, 'Admin'),
(3, 'Guest');


INSERT INTO `RegisteredUsers` (tracking_id, email, first_name, last_name, role_id) 
VALUES
(1, 'admin@example.com', 'Owner', 'One', 1), 
(2, 'owner@example.com', 'Owner', 'Two', 1), 
(3, 'owner2@example.com', 'Owner', 'Three', 1); 

INSERT INTO `Portfolios` (portfolio_id, num_properties, last_appraised_val)
VALUES
(1, 3, 3000000),
(2, 2, 700000),
(3, 1, 1000000);

INSERT INTO `UserPortfolios` (user_id, portfolio_id, last_appraised_val)
VALUES
(1, 1, '3000000'),
(2, 2, '700000'),
(3, 3, '1000000');

-- Insert for Addresses
INSERT INTO `Addresses` (country, state_province, city, street, number)
VALUES
('USA', 'California', 'Los Angeles', 'Sunset Blvd', 101),
('USA', 'California', 'Los Angeles', 'Hollywood Blvd', 202),
('USA', 'New York', 'New York City', '5th Ave', 303),
('USA', 'Florida', 'Miami', 'Ocean Dr', 404),
('USA', 'Texas', 'Houston', 'Main St', 505),
('USA', 'Illinois', 'Chicago', 'Lake Shore Dr', 606);


INSERT INTO `Properties` (total_rent, monthly_capex, bedroom_count, bathroom_count, sqft, lot_size, target_arv, address_id)
VALUES
(5000, 500, 3, 2, 1800, 5000, 1000000, 1),
(2500, 250, 2, 1, 900, 2000, 500000, 2),
(5500, 550, 3, 2, 1500, 4000, 1500000, 3),
(1000, 100, 1, 1, 1200, 1200, 300000, 4),
(1100, 110, 1, 1, 1300, 1300, 400000, 5),
(5500, 550, 4, 2,  2000, 6000, 1000000, 6);


INSERT INTO `PortfolioProperties` (property_id, portfolio_id, property_rent)
VALUES
(1, 1, 5000),
(2, 1, 2500),
(3, 1, 5500),
(4, 2, 1000),
(5, 2, 1100),
(6, 3, 5500);

INSERT INTO `TaxRecords` (property_id, payment_date, due_date, amount_paid, year)
VALUES
(1, '2024-03-01', '2024-03-15', 5000, 2024),
(2, '2024-04-01', '2024-04-15', 2500, 2024),
(3, '2024-05-01', '2024-05-15', 5500, 2024),
(4, '2024-06-01', '2024-06-15', 1000, 2024),
(5, '2024-07-01', '2024-07-15', 1100, 2024),
(6, '2024-08-01', '2024-08-15', 5500, 2024);

INSERT INTO `Mortgages` (lender_name, principal_balance, interest_rate, monthly_payment, start_date, end_date, property_id, terms)
VALUES
('Bank A', 400000, 3.5, 1800, '2000-01-01', '2030-01-01', 1, '30-year fixed'),
('Bank B', 200000, 4.0, 1200, '2001-02-01', '2026-02-01', 2, '25-year fixed'),
('Bank C', 500000, 3.8, 2400, '2024-03-01', '2054-03-01', 3, '30-year fixed'),
('Bank D', 150000, 3.6, 800, '2005-04-01', '2025-04-01', 4, '20-year fixed'),
('Bank E', 250000, 3.9, 1300, '2010-05-01', '2035-05-01', 5, '25-year fixed'),
('Bank F', 600000, 3.7, 2800, '2007-06-01', '2037-06-01', 6, '30-year fixed');


-- Insert for InsurancePolicies
INSERT INTO `InsurancePolicies` (policy_number, provider, monthly_cost, start_date, end_date, property_id)
VALUES
(101, 'Insurance Co A', 150, '2024-01-01', '2025-01-01', 1),
(102, 'Insurance Co B', 120, '2024-02-01', '2025-02-01', 2),
(103, 'Insurance Co C', 180, '2024-03-01', '2025-03-01', 3),
(104, 'Insurance Co D', 100, '2024-04-01', '2025-04-01', 4),
(105, 'Insurance Co E', 110, '2024-05-01', '2025-05-01', 5),
(106, 'Insurance Co F', 160, '2024-06-01', '2025-06-01', 6);

-- Insert for ProjectInfos
INSERT INTO `ProjectInfos` (in_progress, project_title, project_description, ProjectInfoscol, property_id)
VALUES
(1, 'Kitchen Renovation', 'Renovating the kitchen for better functionality.', 'Additional Notes', 1),
(0, 'Bathroom Remodel', 'Updating the bathroom with new fixtures and tiles.', 'Details here', 2),
(1, 'Roof Repair', 'Fixing leaks and ensuring the roof is stable.', 'Roof inspection due soon', 3),
(0, 'Landscaping', 'Landscaping the front yard to increase curb appeal.', 'Final design pending', 4),
(1, 'HVAC System Upgrade', 'Installing new energy-efficient HVAC system.', 'Work in progress', 5),
(0, 'Foundation Inspection', 'Inspecting the foundation for any structural issues.', 'Scheduled for next month', 6);

-- Insert for ProjectUpdates
INSERT INTO `ProjectUpdates` (project_id, updates, date)
VALUES
(1, 'Started demolition of old cabinets and countertops.', '2024-01-10'),
(2, 'Demolition complete, tiles selected for new bathroom.', '2024-02-20'),
(3, 'Roof inspection complete, materials ordered for repair.', '2024-03-05'),
(4, 'Landscaping team has started work on the front yard.', '2024-04-01'),
(5, 'HVAC system installation started, ducts being replaced.', '2024-05-10'),
(6, 'Foundation inspection scheduled for next week.', '2024-06-15');

-- Insert for Contractors
INSERT INTO `Contractors` (company_name, services, first_name, last_name)
VALUES
('Construction Co A', 'General contracting, kitchen remodel', 'John', 'Doe'),
('Construction Co B', 'Bathroom remodeling, plumbing', 'Jane', 'Smith'),
('Roofing Co C', 'Roof repairs, maintenance', 'Michael', 'Johnson'),
('Landscaping Co D', 'Landscaping, yard design', 'Emily', 'Brown'),
('HVAC Co E', 'HVAC installation, maintenance', 'David', 'White'),
('Foundation Co F', 'Foundation inspection and repair', 'Sarah', 'Davis');

-- Insert for ProjectContractors
INSERT INTO `ProjectContractors` (project_id, contractor_id, services)
VALUES
(1, 1, 'General contracting, kitchen remodel'),
(2, 2, 'Bathroom remodeling, plumbing'),
(3, 3, 'Roof repairs, maintenance'),
(4, 4, 'Landscaping, yard design'),
(5, 5, 'HVAC installation, maintenance'),
(6, 6, 'Foundation inspection and repair');

-- Insert for PropertyHistories
INSERT INTO `PropertyHistories` (purchase_price, maintenance_notes, last_appraised_val, purchase_date, property_id)
VALUES
(800000, 'Kitchen remodel completed in 2024', 800000, '2023-05-01', 1),
(1700000, 'Bathroom renovation started in 2024', 1700000, '2023-06-01', 2),
(500000, 'Roof repairs scheduled for 2024', 500000, '2023-07-01', 3),
(700000, 'Landscaping improvements in progress', 700000, '2023-08-01', 4),
(600000, 'HVAC system upgrade in progress', 600000, '2023-09-01', 5),
(650000, 'Foundation inspection pending', 650000, '2023-10-01', 6);

-- Insert for ExpenseHistories
INSERT INTO `ExpenseHistories` (date, cost, label, history_id)
VALUES
('2024-01-01', 5000, 'Kitchen remodel', 1),
('2024-02-01', 2500, 'Bathroom renovation', 2),
('2024-03-01', 3000, 'Roof repairs', 3),
('2024-04-01', 1500, 'Landscaping', 4),
('2024-05-01', 2000, 'HVAC upgrade', 5),
('2024-06-01', 2500, 'Foundation inspection', 6);

-- Insert for InspectionRecords
INSERT INTO `InspectionRecords` (notes, inspector_firstname, inspector_lastname, history_id)
VALUES
('Kitchen remodel completed successfully', 'James', 'Taylor', 1),
('Bathroom renovation is 50% complete', 'Linda', 'Martinez', 2),
('Roof repairs scheduled for March 2024', 'Robert', 'Lee', 3),
('Landscaping improvements started', 'Patricia', 'Harris', 4),
('HVAC system upgrade in progress', 'William', 'Clark', 5),
('Foundation inspection results pending', 'Elizabeth', 'Lewis', 6);

-- Insert for Units
INSERT INTO `Units` (property_id, bedroom_count, bathroom_count, rent, vacant, address_id)
VALUES
(1, 3, 2, 5000, 1, 1),
(2, 2, 1, 2500, 0, 2),
(3, 3, 2, 5500, 0, 3),
(4, 1, 1, 1000, 1, 4),
(5, 1, 1, 1100, 0, 5),
(6, 4, 2, 5500, 1, 6);

-- Insert for LeaseAgreements
INSERT INTO `LeaseAgreements` (rent, start_date, end_date, terms, property_id)
VALUES
(5000, '2024-01-01', '2025-01-01', '12-month lease', 1),
(2500, '2024-02-01', '2025-02-01', '12-month lease', 2),
(5500, '2024-03-01', '2025-03-01', '12-month lease', 3),
(1000, '2024-04-01', '2025-04-01', '12-month lease', 4),
(1100, '2024-05-01', '2025-05-01', '12-month lease', 5),
(5500, '2024-06-01', '2025-06-01', '12-month lease', 6);

-- Insert for Tenants
INSERT INTO `Tenants` (notes, first_name, last_name, lease_id, past_due_balance)
VALUES
('Tenant is a reliable renter.', 'John', 'Doe', 1, 0),
('Tenant moved in early.', 'Jane', 'Smith', 2, 0),
('Tenant is late with payments.', 'Alice', 'Johnson', 3, 11000 ),
('Tenant is renting a small studio.', 'Michael', 'Williams', 4, 0),
('Tenant has a family of three.', 'Emily', 'Brown', 5, 0),
('Tenant requested an extension.', 'Daniel', 'Davis', 6, 5500);

-- Insert for PaymentHistories
INSERT INTO `PaymentHistories` (amount, paid_date, due_date, unit_id, tenant_id)
VALUES
(5000, '2024-11-29', '2024-12-01', 1, 1),
(2500, '2024-12-01', '2024-12-01', 2, 2),
(5500, '2024-10-01', '2024-12-01', 3, 3),
(1000, '2024-12-01', '2024-12-01', 4, 4),
(1100, '2024-11-29', '2024-12-01', 5, 5),
(5500, '2024-11-01', '2024-12-01', 6, 6);

-- Insert for UnitTenants
INSERT INTO `UnitTenants` (unit_id, tenant_id, tenant_name, address_id, lease_id)
VALUES
(1, 1, 'John Doe', 1, 1),
(2, 2, 'Jane Smith', 2, 2),
(3, 3, 'Alice Johnson', 3, 3),
(4, 4, 'Michael Williams', 4, 4),
(5, 5, 'Emily Brown', 5, 5),
(6, 6, 'Daniel Davis', 6, 6);
