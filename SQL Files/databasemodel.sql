-- MySQL Workbench Forward Engineering
DROP DATABASE IF EXISTS PropertyManagementDB;
CREATE DATABASE PropertyManagementDB;
USE PropertyManagementDB;

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema PropertyManagementDB
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Table `Roles`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Roles` ;

CREATE TABLE IF NOT EXISTS `Roles` (
  `role_id` INT NOT NULL AUTO_INCREMENT,
  `role_type` ENUM('Admin', 'Owner', 'Guest') NULL,
  PRIMARY KEY (`role_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `RegisteredUsers`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `RegisteredUsers` ;

CREATE TABLE IF NOT EXISTS `RegisteredUsers` (
  `tracking_id` BIGINT(20) UNSIGNED NOT NULL,
  `email` VARCHAR(45) NOT NULL,
  `first_name` VARCHAR(45) NULL,
  `last_name` VARCHAR(45) NULL,
  `full_name` VARCHAR(100) GENERATED ALWAYS AS (CONCAT(first_name, ' ', last_name)
) VIRTUAL,
  `role_id` INT NULL,
  `role_expires` DATE NULL,
  `has_sample_data` TINYINT NOT NULL DEFAULT 0,
  PRIMARY KEY (`tracking_id`),
  UNIQUE INDEX `email_UNIQUE` (`email` ASC) VISIBLE,
  INDEX `role_id_idx` (`role_id` ASC) VISIBLE,
  CONSTRAINT `fk_RegisteredUsers_Role`
    FOREIGN KEY (`role_id`)
    REFERENCES `Roles` (`role_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Portfolios`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Portfolios` ;

CREATE TABLE IF NOT EXISTS `Portfolios` (
  `portfolio_id` INT NOT NULL AUTO_INCREMENT,
  `num_properties` INT NOT NULL DEFAULT 0,
  `last_appraised_val` VARCHAR(45) NOT NULL DEFAULT 0,
  PRIMARY KEY (`portfolio_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `UserPortfolios`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `UserPortfolios` ;

CREATE TABLE IF NOT EXISTS `UserPortfolios` (
  `tracking_id` INT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT(20) UNSIGNED NULL,
  `portfolio_id` INT NULL,
  `last_appraised_val` VARCHAR(45) NULL,
  PRIMARY KEY (`tracking_id`),
  INDEX `portfolio_id_idx` (`portfolio_id` ASC) VISIBLE,
  INDEX `fk_UserPortfolios_RUser_idx` (`user_id` ASC) VISIBLE,
  CONSTRAINT `fk_UserPortfolios_RUser`
    FOREIGN KEY (`user_id`)
    REFERENCES `RegisteredUsers` (`tracking_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_UserPortfolios_Portfolio`
    FOREIGN KEY (`portfolio_id`)
    REFERENCES `Portfolios` (`portfolio_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Addresses`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Addresses` ;

CREATE TABLE IF NOT EXISTS `Addresses` (
  `address_id` INT NOT NULL AUTO_INCREMENT,
  `country` VARCHAR(45) NULL,
  `state_province` VARCHAR(45) NULL,
  `city` VARCHAR(45) NULL,
  `street` VARCHAR(45) NULL,
  `number` INT NULL,
  `numbered_street` VARCHAR(45) GENERATED ALWAYS AS (CONCAT(number, ' ', street)) VIRTUAL,
  PRIMARY KEY (`address_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Properties`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Properties` ;

CREATE TABLE IF NOT EXISTS `Properties` (
  `total_rent` DOUBLE NULL DEFAULT 0,
  `property_id` INT NOT NULL AUTO_INCREMENT,
  `monthly_capex` DOUBLE NULL,
  `bedroom_count` INT NULL,
  `bathroom_count` INT NULL,
  `sqft` INT NULL,
  `lot_size` INT NULL,
  `target_arv` DOUBLE NULL,
  `address_id` INT NULL,
  PRIMARY KEY (`property_id`),
  INDEX `fk_Properties_Address_idx` (`address_id` ASC) VISIBLE,
  CONSTRAINT `fk_Properties_Address`
    FOREIGN KEY (`address_id`)
    REFERENCES `Addresses` (`address_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `PortfolioProperties`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `PortfolioProperties` ;

CREATE TABLE IF NOT EXISTS `PortfolioProperties` (
  `tracking_id` INT NOT NULL AUTO_INCREMENT,
  `property_id` INT NOT NULL,
  `portfolio_id` INT NOT NULL,
  `property_rent` DOUBLE NULL,
  PRIMARY KEY (`tracking_id`),
  INDEX `fk_PortfolioProperties_Properties1_idx` (`property_id` ASC) VISIBLE,
  INDEX `fk_PortfolioProperties_Portfolios1_idx` (`portfolio_id` ASC) VISIBLE,
  CONSTRAINT `fk_PortfolioProperties_Properties`
    FOREIGN KEY (`property_id`)
    REFERENCES `Properties` (`property_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_PortfolioProperties_Portfolios`
    FOREIGN KEY (`portfolio_id`)
    REFERENCES `Portfolios` (`portfolio_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TaxRecords`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `TaxRecords` ;

CREATE TABLE IF NOT EXISTS `TaxRecords` (
  `tracking_id` INT NOT NULL AUTO_INCREMENT,
  `property_id` INT NULL,
  `payment_date` DATE NULL,
  `due_date` DATE NULL,
  `amount_paid` DOUBLE NULL,
  `year` INT NULL,
  PRIMARY KEY (`tracking_id`),
  INDEX `property_id_idx` (`property_id` ASC) VISIBLE,
  CONSTRAINT `fk_TaxRecords_Property`
    FOREIGN KEY (`property_id`)
    REFERENCES `Properties` (`property_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Mortgages`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Mortgages` ;

CREATE TABLE IF NOT EXISTS `Mortgages` (
  `tracking_id` INT NOT NULL AUTO_INCREMENT,
  `lender_name` VARCHAR(45) NULL,
  `principal_balance` DOUBLE NULL,
  `interest_rate` DOUBLE NULL,
  `monthly_payment` DOUBLE NULL,
  `start_date` DATE NULL,
  `end_date` DATE NULL,
  `property_id` INT NULL,
  `terms` LONGTEXT NULL,
  PRIMARY KEY (`tracking_id`),
  INDEX `property_id_idx` (`property_id` ASC) VISIBLE,
  CONSTRAINT `fk_Mortgages_Property`
    FOREIGN KEY (`property_id`)
    REFERENCES `Properties` (`property_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `InsurancePolicies`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `InsurancePolicies` ;

CREATE TABLE IF NOT EXISTS `InsurancePolicies` (
  `tracking_id` INT NOT NULL AUTO_INCREMENT,
  `policy_number` INT NULL,
  `provider` VARCHAR(45) NULL,
  `monthly_cost` DOUBLE NULL,
  `start_date` DATE NULL,
  `end_date` DATE NULL,
  `property_id` INT NULL,
  PRIMARY KEY (`tracking_id`),
  INDEX `property_id_idx` (`property_id` ASC) VISIBLE,
  CONSTRAINT `fk_InsurancePolicies_Property`
    FOREIGN KEY (`property_id`)
    REFERENCES `Properties` (`property_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ProjectInfos`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `ProjectInfos` ;

CREATE TABLE IF NOT EXISTS `ProjectInfos` (
  `project_id` INT NOT NULL AUTO_INCREMENT,
  `in_progress` TINYINT NULL,
  `project_title` VARCHAR(100) NULL,
  `project_description` LONGTEXT NULL,
  `ProjectInfoscol` VARCHAR(45) NULL,
  `property_id` INT NULL,
  PRIMARY KEY (`project_id`),
  INDEX `property_id_idx` (`property_id` ASC) VISIBLE,
  CONSTRAINT `fk_ProjectInfos_Property`
    FOREIGN KEY (`property_id`)
    REFERENCES `Properties` (`property_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ProjectUpdates`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `ProjectUpdates` ;

CREATE TABLE IF NOT EXISTS `ProjectUpdates` (
  `update_id` INT NOT NULL AUTO_INCREMENT,
  `project_id` INT NOT NULL,
  `updates` LONGTEXT NULL,
  `date` DATE NULL,
  PRIMARY KEY (`update_id`),
  INDEX `project_id_idx` (`project_id` ASC) VISIBLE,
  CONSTRAINT `fk_ProjectInfos_Project`
    FOREIGN KEY (`project_id`)
    REFERENCES `ProjectInfos` (`project_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Contractors`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Contractors` ;

CREATE TABLE IF NOT EXISTS `Contractors` (
  `tracking_id` INT NOT NULL AUTO_INCREMENT,
  `company_name` VARCHAR(45) NULL,
  `services` MEDIUMTEXT NULL,
  `first_name` VARCHAR(45) NULL,
  `last_name` VARCHAR(45) NULL,
  `full_name` VARCHAR(100) GENERATED ALWAYS AS (CONCAT(first_name, ' ', last_name)) VIRTUAL,
  `user_id` BIGINT(20) UNSIGNED NOT NULL,
  PRIMARY KEY (`tracking_id`),
  INDEX `fk_Contractors_RUser_idx` (`user_id` ASC) VISIBLE,
  CONSTRAINT `fk_Contractors_RUser`
    FOREIGN KEY (`user_id`)
    REFERENCES `RegisteredUsers` (`tracking_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ProjectContractors`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `ProjectContractors` ;

CREATE TABLE IF NOT EXISTS `ProjectContractors` (
  `tracking_id` INT NOT NULL AUTO_INCREMENT,
  `project_id` INT NULL,
  `contractor_id` INT NULL,
  `services` MEDIUMTEXT NULL,
  PRIMARY KEY (`tracking_id`),
  INDEX `project_id_idx` (`project_id` ASC) VISIBLE,
  INDEX `contractor_id_idx` (`contractor_id` ASC) VISIBLE,
  CONSTRAINT `fk_ProjectContractors_Project`
    FOREIGN KEY (`project_id`)
    REFERENCES `ProjectInfos` (`project_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_ProjectContractors_Contractor`
    FOREIGN KEY (`contractor_id`)
    REFERENCES `Contractors` (`tracking_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `PropertyHistories`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `PropertyHistories` ;

CREATE TABLE IF NOT EXISTS `PropertyHistories` (
  `purchase_price` DOUBLE NULL,
  `history_id` INT NOT NULL AUTO_INCREMENT,
  `maintenance_notes` LONGTEXT NULL,
  `last_appraised_val` DOUBLE NULL,
  `purchase_date` DATE NULL,
  `property_id` INT NULL,
  PRIMARY KEY (`history_id`),
  INDEX `property_id_idx` (`property_id` ASC) VISIBLE,
  CONSTRAINT `fk_PropertyHistories_Property`
    FOREIGN KEY (`property_id`)
    REFERENCES `Properties` (`property_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ExpenseHistories`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `ExpenseHistories` ;

CREATE TABLE IF NOT EXISTS `ExpenseHistories` (
  `expense_id` INT NOT NULL AUTO_INCREMENT,
  `date` DATE NULL,
  `cost` DOUBLE NULL,
  `label` VARCHAR(45) NULL,
  `history_id` INT NULL,
  `ExpenseHistoriescol` VARCHAR(45) NULL,
  PRIMARY KEY (`expense_id`),
  INDEX `history_id_idx` (`history_id` ASC) VISIBLE,
  CONSTRAINT `fk_ExpenseHistories_History`
    FOREIGN KEY (`history_id`)
    REFERENCES `PropertyHistories` (`history_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `InspectionRecords`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `InspectionRecords` ;

CREATE TABLE IF NOT EXISTS `InspectionRecords` (
  `inspection_id` INT NOT NULL AUTO_INCREMENT,
  `notes` LONGTEXT NULL,
  `inspector_firstname` VARCHAR(45) NULL,
  `inspector_lastname` VARCHAR(45) NULL,
  `inspector_name` VARCHAR(100) GENERATED ALWAYS AS (CONCAT(inspector_firstname, ' ', inspector_lastname)) VIRTUAL,
  `history_id` INT NULL,
  PRIMARY KEY (`inspection_id`),
  INDEX `history_id_idx` (`history_id` ASC) VISIBLE,
  CONSTRAINT `fk_InspectionRecords_History`
    FOREIGN KEY (`history_id`)
    REFERENCES `PropertyHistories` (`history_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Units`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Units` ;

CREATE TABLE IF NOT EXISTS `Units` (
  `unit_id` INT NOT NULL AUTO_INCREMENT,
  `property_id` INT NULL,
  `bedroom_count` INT NULL,
  `bathroom_count` INT NULL,
  `rent` DOUBLE NULL,
  `vacant` TINYINT NULL,
  `address_id` INT NULL,
  `Unitscol` VARCHAR(45) NULL,
  PRIMARY KEY (`unit_id`),
  INDEX `property_id_idx` (`property_id` ASC) VISIBLE,
  INDEX `address_idx` (`address_id` ASC) VISIBLE,
  CONSTRAINT `fk_Units_Property`
    FOREIGN KEY (`property_id`)
    REFERENCES `Properties` (`property_id`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  CONSTRAINT `fk_Units_Address`
    FOREIGN KEY (`address_id`)
    REFERENCES `Addresses` (`address_id`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `LeaseAgreements`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `LeaseAgreements` ;

CREATE TABLE IF NOT EXISTS `LeaseAgreements` (
  `lease_id` INT NOT NULL AUTO_INCREMENT,
  `rent` DOUBLE NULL,
  `start_date` DATE NULL,
  `end_date` DATE NULL,
  `terms` LONGTEXT NULL,
  `property_id` INT NULL,
  PRIMARY KEY (`lease_id`),
  INDEX `property_id_idx` (`property_id` ASC) VISIBLE,
  CONSTRAINT `fk_LeaseAgreements_Property`
    FOREIGN KEY (`property_id`)
    REFERENCES `Properties` (`property_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Tenants`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Tenants` ;

CREATE TABLE IF NOT EXISTS `Tenants` (
  `tenant_id` INT NOT NULL AUTO_INCREMENT,
  `notes` LONGTEXT NULL,
  `first_name` VARCHAR(45) NULL,
  `last_name` VARCHAR(45) NULL,
  `full_name` VARCHAR(100) GENERATED ALWAYS AS (CONCAT(first_name, ' ', last_name) ) VIRTUAL,
  `lease_id` INT NULL,
  `past_due_balance` INT NULL,
  PRIMARY KEY (`tenant_id`),
  INDEX `lease_id_idx` (`lease_id` ASC) VISIBLE,
  CONSTRAINT `fk_Tenants_Lease`
    FOREIGN KEY (`lease_id`)
    REFERENCES `LeaseAgreements` (`lease_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `PaymentHistories`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `PaymentHistories` ;

CREATE TABLE IF NOT EXISTS `PaymentHistories` (
  `history_id` INT NOT NULL AUTO_INCREMENT,
  `amount` DOUBLE NULL,
  `paid_date` DATE NULL,
  `due_date` DATE NULL,
  `unit_id` INT NULL,
  `tenant_id` INT NULL,
  PRIMARY KEY (`history_id`),
  INDEX `unit_id_idx` (`unit_id` ASC) VISIBLE,
  INDEX `tenant_id_idx` (`tenant_id` ASC) VISIBLE,
  CONSTRAINT `fk_PaymentHistories_Unit`
    FOREIGN KEY (`unit_id`)
    REFERENCES `Units` (`unit_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_PaymentHistories_Tenant`
    FOREIGN KEY (`tenant_id`)
    REFERENCES `Tenants` (`tenant_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `UnitTenants`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `UnitTenants` ;

CREATE TABLE IF NOT EXISTS `UnitTenants` (
  `tracking_id` INT NOT NULL AUTO_INCREMENT,
  `unit_id` INT NULL,
  `tenant_id` INT NULL,
  `tenant_name` VARCHAR(100) NULL,
  `address_id` INT NULL,
  `lease_id` INT NULL,
  `UnitTenantscol` VARCHAR(45) NULL,
  PRIMARY KEY (`tracking_id`),
  INDEX `unit_id_idx` (`unit_id` ASC) VISIBLE,
  INDEX `tenant_id_idx` (`tenant_id` ASC) VISIBLE,
  INDEX `fk_UnitTenants_Lease_idx` (`lease_id` ASC) VISIBLE,
  INDEX `fk_UnitTenants_Address_idx` (`address_id` ASC) VISIBLE,
  CONSTRAINT `fk_UnitTenants_Unit`
    FOREIGN KEY (`unit_id`)
    REFERENCES `Units` (`unit_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_UnitTenants_Tenant`
    FOREIGN KEY (`tenant_id`)
    REFERENCES `Tenants` (`tenant_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_UnitTenants_Lease`
    FOREIGN KEY (`lease_id`)
    REFERENCES `LeaseAgreements` (`lease_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_UnitTenants_Address`
    FOREIGN KEY (`address_id`)
    REFERENCES `Addresses` (`address_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
