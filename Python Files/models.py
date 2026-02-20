from database import *

class ModelInterface:

    def synchronize(self):
        pass

    def update(self, data):
        pass

    def delete(self, condition = None):
        pass

    def unwrap(self):
        pass

class ModelFactory:
        # Makes and gets all the models

    @staticmethod
    def make(table_identifier, data):

        if table_identifier == Tables.ADDRESSES:
            Database.insert(Query.INSERT_ADDRESS, values = data)

        if table_identifier == Tables.CONTRACTORS:
            Database.insert(Query.INSERT_CONTRACTOR, values = data)

        if table_identifier == Tables.EXPENSE_HISTORIES:
            Database.insert(Query.INSERT_EXPENSE_HISTORY, values = data)

        if table_identifier == Tables.INSPECTION_RECORDS:
            Database.insert(Query.INSERT_INSPECTION_RECORD, values = data)

        if table_identifier == Tables.INSURANCE_POLICIES:
            Database.insert(Query.INSERT_INSURANCE_POLICY, values = data)

        if table_identifier == Tables.LEASE_AGREEMENTS:
            Database.insert(Query.INSERT_LEASE_AGREEMENT, values = data)
            
        if table_identifier == Tables.MORTGAGES:
            Database.insert(Query.INSERT_MORTGAGE, values = data)
            
        if table_identifier == Tables.PAYMENT_HISTORIES:
            Database.insert(Query.INSERT_PAYMENT_HISTORY, values = data)
            
        if table_identifier == Tables.PORTFOLIO_PROPERTIES:
            Database.insert(Query.INSERT_PORTFOLIO_PROPERTY, values = data)
       
        if table_identifier == Tables.PORTFOLIOS:
            Database.insert(Query.INSERT_PORTFOLIO, values = data)
            
        if table_identifier == Tables.PROJECT_CONTRACTORS:
            Database.insert(Query.INSERT_PROJECT_CONTRACTOR, values = data)
            
        if table_identifier == Tables.PROJECT_INFOS:
            Database.insert(Query.INSERT_PROJECT_INFO, values = data)
            
        if table_identifier == Tables.PROJECT_UPDATES:
            Database.insert(Query.INSERT_PROJECT_UPDATE, values = data)
            
        if table_identifier == Tables.PROPERTIES:
            Database.insert(Query.INSERT_PROPERTIES, values = data)
            
        if table_identifier == Tables.PROPERTY_HISTORIES:
            Database.insert(Query.INSERT_PROPERTY_HISTORY, values = data)

        if table_identifier == Tables.REGISTERED_USERS:
            Database.insert(Query.INSERT_REGISTERED_USER, values = data)
            
        if table_identifier == Tables.TAX_RECORDS:
            Database.insert(Query.INSERT_TAX_RECORDS, values = data)
            
        if table_identifier == Tables.TENANTS:
            Database.insert(Query.INSERT_TENANT, values = data)

        if table_identifier == Tables.UNITS:
            Database.insert(Query.INSERT_UNIT, values = data)
            
        if table_identifier == Tables.UNIT_TENANTS:
            Database.insert(Query.INSERT_UNIT_TENANT, values = data)
            
        if table_identifier == Tables.USER_PORTFOLIOS:
            Database.insert(Query.INSERT_USER_PORTFOLIO, values = data)

        
        return getBy(table_identifier, data["tracking_id"])

@staticmethod
def getBy(table_identifier, entity_identifier):

    table_map = {
        Tables.ROLES: RoleModel,
        Tables.REGISTERED_USERS: RegisteredUserModel,
        Tables.PORTFOLIOS: PortfolioModel,
        Tables.USER_PORTFOLIOS: UserPortfolioModel,
        Tables.ADDRESSES: AddressModel,
        Tables.PROPERTIES: PropertyModel,
        Tables.PORTFOLIO_PROPERTIES: PortfolioPropertyModel,
        Tables.TAX_RECORDS: TaxRecordModel,
        Tables.MORTGAGES: MortgageModel,
        Tables.INSURANCE_POLICIES: InsurancePolicyModel,
        Tables.PROJECT_INFOS: ProjectInfoModel,
        Tables.PROJECT_UPDATES: ProjectUpdateModel,
        Tables.CONTRACTORS: ContractorModel,
        Tables.PROJECT_CONTRACTORS: ProjectContractorModel,
        Tables.PROPERTY_HISTORIES: PropertyHistoryModel,
        Tables.EXPENSE_HISTORIES: ExpenseHistoryModel,
        Tables.INSPECTION_RECORDS: InspectionRecordModel,
        Tables.UNITS: UnitModel,
        Tables.LEASE_AGREEMENTS: LeaseAgreementModel,
        Tables.TENANTS: TenantModel,
        Tables.PAYMENT_HISTORIES: PaymentHistoryModel,
        Tables.UNIT_TENANTS: UnitTenantModel,
        Tables.PORTFOLIO_PERFORMANCE: PortfolioPerformanceModel,
        Tables.VIEW_TENANTS: ViewTenantsModel,
        Tables.VIEW_MORTGAGES: ViewMortgagesModel,
        Tables.CURRENT_PROJECTS: CurrentProjectsModel,
    }

    if table_identifier not in table_map:
        raise ValueError(f"Unknown table identifier: {table_identifier}")

    return table_map[table_identifier](entity_identifier)

        

# -------------------------------------------------------------------
# Models for each entity
# -------------------------------------------------------------------

class AddressModel(ModelInterface):

    def __init__(self, address_id):
        self.address_id = address_id
        self.country = None
        self.state_province = None
        self.city = None
        self.street = None
        self.number = None
        self.numbered_street = None
        self._load()

    def _load(self):
        data = Database.select(Query.ADDRESS, (self.address_id,))
        if not data:
            return

        row = data[0]
        self.country = row.get("country")
        self.state_province = row.get("state_province")
        self.city = row.get("city")
        self.street = row.get("street")
        self.number = row.get("number")
        self.numbered_street = row.get("numbered_street")


class ContractorModel(ModelInterface):

    def __init__(self, tracking_id):
        self.tracking_id = tracking_id
        self.company_name = None
        self.services = None
        self.first_name = None
        self.last_name = None
        self.full_name = None
        self._load()

    def _load(self):
        data = Database.select(Query.CONTRACTOR, (self.tracking_id,))
        if not data:
            return

        row = data[0]
        self.company_name = row.get("company_name")
        self.services = row.get("services")
        self.first_name = row.get("first_name")
        self.last_name = row.get("last_name")
        self.full_name = row.get("full_name")


class ExpenseHistoryModel(ModelInterface):

    def __init__(self, expense_id):
        self.expense_id = expense_id
        self.date = None
        self.cost = None
        self.label = None
        self.history_id = None
        self.ExpenseHistoriescol = None
        self._load()

    def _load(self):
        data = Database.select(Query.EXPENSE_HISTORY, (self.expense_id,))
        if not data:
            return

        row = data[0]
        self.date = row.get("date")
        self.cost = row.get("cost")
        self.label = row.get("label")
        self.history_id = row.get("history_id")
        self.ExpenseHistoriescol = row.get("ExpenseHistoriescol")


class InspectionRecordModel(ModelInterface):

    def __init__(self, inspection_id):
        self.inspection_id = inspection_id
        self.notes = None
        self.inspector_firstname = None
        self.inspector_lastname = None
        self.inspector_name = None
        self.history_id = None
        self._load()

    def _load(self):
        data = Database.select(Query.INSPECTION_RECORD, (self.inspection_id,))
        if not data:
            return

        row = data[0]
        self.notes = row.get("notes")
        self.inspector_firstname = row.get("inspector_firstname")
        self.inspector_lastname = row.get("inspector_lastname")
        self.inspector_name = row.get("inspector_name")
        self.history_id = row.get("history_id")



class InsurancePolicyModel(ModelInterface):

    def __init__(self, tracking_id):
        self.tracking_id = tracking_id
        self.policy_number = None
        self.provider = None
        self.monthly_cost = None
        self.start_date = None
        self.end_date = None
        self.property_id = None
        self._load()

    def _load(self):
        data = Database.select(Query.INSURANCE_POLICY, (self.tracking_id,))
        if not data:
            return

        row = data[0]
        self.policy_number = row.get("policy_number")
        self.provider = row.get("provider")
        self.monthly_cost = row.get("monthly_cost")
        self.start_date = row.get("start_date")
        self.end_date = row.get("end_date")
        self.property_id = row.get("property_id")


class LeaseAgreementModel(ModelInterface):

    def __init__(self, lease_id):
        self.lease_id = lease_id
        self.rent = None
        self.start_date = None
        self.end_date = None
        self.terms = None
        self.property_id = None
        self._load()

    def _load(self):
        data = Database.select(Query.LEASE_AGREEMENT, (self.lease_id,))
        if not data:
            return

        row = data[0]
        self.rent = row.get("rent")
        self.start_date = row.get("start_date")
        self.end_date = row.get("end_date")
        self.terms = row.get("terms")
        self.property_id = row.get("property_id")


class MortgageModel(ModelInterface):

    def __init__(self, tracking_id):
        self.tracking_id = tracking_id
        self.lender_name = None
        self.principal_balance = None
        self.interest_rate = None
        self.monthly_payment = None
        self.start_date = None
        self.end_date = None
        self.property_id = None
        self.terms = None
        self._load()

    def _load(self):
        data = Database.select(Query.MORTGAGE, (self.tracking_id,))
        if not data:
            return

        row = data[0]
        self.lender_name = row.get("lender_name")
        self.principal_balance = row.get("principal_balance")
        self.interest_rate = row.get("interest_rate")
        self.monthly_payment = row.get("monthly_payment")
        self.start_date = row.get("start_date")
        self.end_date = row.get("end_date")
        self.property_id = row.get("property_id")
        self.terms = row.get("terms")

class PaymentHistoryModel(ModelInterface):

    def __init__(self, history_id):
        self.history_id = history_id
        self.amount = None
        self.paid_date = None
        self.due_date = None
        self.unit_id = None
        self.tenant_id = None
        self._load()

    def _load(self):
        data = Database.select(Query.PAYMENT_HISTORY, (self.history_id,))
        if not data:
            return

        row = data[0]
        self.amount = row.get("amount")
        self.paid_date = row.get("paid_date")
        self.due_date = row.get("due_date")
        self.unit_id = row.get("unit_id")
        self.tenant_id = row.get("tenant_id")


class PortfolioPropertyModel(ModelInterface):

    def __init__(self, tracking_id):
        self.tracking_id = tracking_id
        self.property_id = None
        self.portfolio_id = None
        self.property_rent = None
        self._load()

    def _load(self):
        data = Database.select(Query.PORTFOLIO_PROPERTY, (self.tracking_id,))
        if not data:
            return

        row = data[0]
        self.property_id = row.get("property_id")
        self.portfolio_id = row.get("portfolio_id")
        self.property_rent = row.get("property_rent")


class PortfolioModel(ModelInterface):

    def __init__(self, portfolio_id):
        self.portfolio_id = portfolio_id
        self.num_properties = None
        self.last_appraised_val = None
        self._load()

    def _load(self):
        data = Database.select(Query.PORTFOLIO, (self.portfolio_id,))
        if not data:
            return

        row = data[0]
        self.num_properties = row.get("num_properties")
        self.last_appraised_val = row.get("last_appraised_val")


class ProjectContractorModel(ModelInterface):

    def __init__(self, tracking_id):
        self.tracking_id = tracking_id
        self.project_id = None
        self.contractor_id = None
        self.services = None
        self._load()

    def _load(self):
        data = Database.select(Query.PROJECT_CONTRACTOR, (self.tracking_id,))
        if not data:
            return

        row = data[0]
        self.project_id = row.get("project_id")
        self.contractor_id = row.get("contractor_id")
        self.services = row.get("services")


class ProjectInfoModel(ModelInterface):

    def __init__(self, project_id):
        self.project_id = project_id
        self.in_progress = None
        self.project_title = None
        self.project_description = None
        self.ProjectInfoscol = None
        self.property_id = None
        self._load()

    def _load(self):
        data = Database.select(Query.PROJECT_INFO, (self.project_id,))
        if not data:
            return

        row = data[0]
        self.in_progress = row.get("in_progress")
        self.project_title = row.get("project_title")
        self.project_description = row.get("project_description")
        self.ProjectInfoscol = row.get("ProjectInfoscol")
        self.property_id = row.get("property_id")


class ProjectUpdateModel(ModelInterface):

    def __init__(self, update_id):
        self.update_id = update_id
        self.project_id = None
        self.updates = None
        self.date = None
        self._load()

    def _load(self):
        data = Database.select(Query.PROJECT_UPDATE, (self.update_id,))
        if not data:
            return

        row = data[0]
        self.project_id = row.get("project_id")
        self.updates = row.get("updates")
        self.date = row.get("date")


class PropertyHistoryModel(ModelInterface):

    def __init__(self, history_id):
        self.history_id = history_id
        self.purchase_price = None
        self.maintenance_notes = None
        self.last_appraised_val = None
        self.purchase_date = None
        self.property_id = None
        self._load()

    def _load(self):
        data = Database.select(Query.PROPERTY_HISTORY, (self.history_id,))
        if not data:
            return

        row = data[0]
        self.purchase_price = row.get("purchase_price")
        self.maintenance_notes = row.get("maintenance_notes")
        self.last_appraised_val = row.get("last_appraised_val")
        self.purchase_date = row.get("purchase_date")
        self.property_id = row.get("property_id")


class PropertyModel(ModelInterface):

    def __init__(self, property_id):
        self.property_id = property_id
        self.total_rent = None
        self.monthly_capex = None
        self.bedroom_count = None
        self.bathroom_count = None
        self.sqft = None
        self.lot_size = None
        self.target_arv = None
        self.address_id = None
        self._load()

    def _load(self):
        data = Database.select(Query.PROPERTY, (self.property_id,))
        if not data:
            return

        row = data[0]
        self.total_rent = row.get("total_rent")
        self.monthly_capex = row.get("monthly_capex")
        self.bedroom_count = row.get("bedroom_count")
        self.bathroom_count = row.get("bathroom_count")
        self.sqft = row.get("sqft")
        self.lot_size = row.get("lot_size")
        self.target_arv = row.get("target_arv")
        self.address_id = row.get("address_id")


class RegisteredUserModel(ModelInterface):

    def __init__(self, identifier):
        self.tracking_id = identifier
        self.email = None
        self.first_name = None
        self.last_name = None
        self.full_name = None
        self.role_id = None
        self.role_expires = None
        self._load()

    def _load(self):
        data = Database.select(Query.REGISTERED_USER, (self.tracking_id,))
        if not data:
            return

        row = data[0]
        self.email = row.get("email")
        self.first_name = row.get("first_name")
        self.last_name = row.get("last_name")
        self.full_name = row.get("full_name")
        self.role_id = row.get("role_id")
        self.role_expires = row.get("role_expires")

class RoleModel(ModelInterface):

    def __init__(self, role_id):
        self.role_id = role_id
        self.role_type = None
        self._load()

    def _load(self):
        data = Database.select(Query.ROLE, (self.role_id,))
        if not data:
            return

        row = data[0]
        self.role_type = row.get("role_type")


class TaxRecordModel(ModelInterface):

    def __init__(self, tracking_id):
        self.tracking_id = tracking_id
        self.property_id = None
        self.payment_date = None
        self.due_date = None
        self.amount_paid = None
        self.year = None
        self._load()

    def _load(self):
        data = Database.select(Query.TAX_RECORD, (self.tracking_id,))
        if not data:
            return

        row = data[0]
        self.property_id = row.get("property_id")
        self.payment_date = row.get("payment_date")
        self.due_date = row.get("due_date")
        self.amount_paid = row.get("amount_paid")
        self.year = row.get("year")


class TenantModel(ModelInterface):

    def __init__(self, tenant_id):
        self.tenant_id = tenant_id
        self.notes = None
        self.first_name = None
        self.last_name = None
        self.full_name = None
        self.lease_id = None
        self.past_due_balance = None
        self._load()

    def _load(self):
        data = Database.select(Query.TENANT, (self.tenant_id,))
        if not data:
            return

        row = data[0]
        self.notes = row.get("notes")
        self.first_name = row.get("first_name")
        self.last_name = row.get("last_name")
        self.full_name = row.get("full_name")
        self.lease_id = row.get("lease_id")
        self.past_due_balance = row.get("past_due_balance")


class UnitModel(ModelInterface):

    def __init__(self, unit_id):
        self.unit_id = unit_id
        self.property_id = None
        self.bedroom_count = None
        self.bathroom_count = None
        self.rent = None
        self.vacant = None
        self.address_id = None
        self.Unitscol = None
        self._load()

    def _load(self):
        data = Database.select(Query.UNIT, (self.unit_id,))
        if not data:
            return

        row = data[0]
        self.property_id = row.get("property_id")
        self.bedroom_count = row.get("bedroom_count")
        self.bathroom_count = row.get("bathroom_count")
        self.rent = row.get("rent")
        self.vacant = row.get("vacant")
        self.address_id = row.get("address_id")
        self.Unitscol = row.get("Unitscol")


class UnitTenantModel(ModelInterface):

    def __init__(self, tracking_id):
        self.tracking_id = tracking_id
        self.unit_id = None
        self.tenant_id = None
        self.tenant_name = None
        self.address_id = None
        self.lease_id = None
        self.UnitTenantscol = None
        self._load()

    def _load(self):
        data = Database.select(Query.UNIT_TENANT, (self.tracking_id,))
        if not data:
            return

        row = data[0]
        self.unit_id = row.get("unit_id")
        self.tenant_id = row.get("tenant_id")
        self.tenant_name = row.get("tenant_name")
        self.address_id = row.get("address_id")
        self.lease_id = row.get("lease_id")
        self.UnitTenantscol = row.get("UnitTenantscol")



class UserPortfolioModel(ModelInterface):

    def __init__(self, tracking_id):
        self.tracking_id = tracking_id
        self.user_id = None
        self.portfolio_id = None
        self.last_appraised_val = None
        self._load()

    def _load(self):
        data = Database.select(Query.USER_PORTFOLIO, (self.tracking_id,))
        if not data:
            return

        row = data[0]
        self.user_id = row.get("user_id")
        self.portfolio_id = row.get("portfolio_id")
        self.last_appraised_val = row.get("last_appraised_val")


class CurrentProjectsModel(ModelInterface):
    # Queries the CurrentProjects view and holds all rows for a given user,
    # ordered by in-progress status first, then by address.

    def __init__(self, user_id):
        self.user_id = user_id
        self.rows = []
        self._load()

    def _load(self):
        data = Database.select(Query.CURRENT_PROJECTS_BY_USER, (self.user_id,))
        if not data:
            return

        self.rows = data


class ViewMortgagesModel(ModelInterface):
    # Queries the ViewMortgages view and holds all rows for a given user,
    # ordered by start date ascending with the totals row last.

    def __init__(self, user_id):
        self.user_id = user_id
        self.rows = []
        self._load()

    def _load(self):
        data = Database.select(Query.MORTGAGES_BY_USER, (self.user_id,))
        if not data:
            return

        self.rows = data


class ViewTenantsModel(ModelInterface):
    # Queries the ViewTenants view and holds all rows for a given user,
    # ordered by past due balance descending (highest first).

    def __init__(self, user_id):
        self.user_id = user_id
        self.rows = []
        self._load()

    def _load(self):
        data = Database.select(Query.TENANTS_BY_USER, (self.user_id,))
        if not data:
            return

        self.rows = data


class PortfolioPerformanceModel(ModelInterface):
    # Queries the PortfolioPerformance view and holds all rows for a given user,
    # ordered by cash flow ascending (worst performers first).

    def __init__(self, user_id):
        self.user_id = user_id
        self.rows = []
        self._load()

    def _load(self):
        data = Database.select(Query.PORTFOLIO_PERFORMANCE_BY_USER, (self.user_id,))
        if not data:
            return

        self.rows = data
