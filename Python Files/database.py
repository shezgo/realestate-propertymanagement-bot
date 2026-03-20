# IMPORTANT: All SQL-related logic must be confined to this file.

import os
import queue
import asyncio
from concurrent.futures import ThreadPoolExecutor
from dotenv import load_dotenv
import pymysql.cursors

POOL_SIZE = 4
_executor = ThreadPoolExecutor(max_workers=POOL_SIZE)

# Load .env if it exists for local development
load_dotenv()

# Environment variables for database connectivity, which are set in environment settings.
db_host = os.environ["DB_HOST"]
db_username = os.environ["DB_USER"]
db_password = os.environ["DB_PASSWORD"]
db_name = os.environ["DB_NAME"]


class ConnectionPool:
    """
    Maintains a fixed set of persistent MySQL connections.
    Connections are checked out by worker threads and returned after each query,
    avoiding the overhead of opening and closing a new TCP connection per query.
    queue.Queue is used as the underlying store — it is thread-safe by design,
    so no explicit mutex is needed to protect the pool itself.
    """

    def __init__(self, size):
        self._pool = queue.Queue(maxsize=size)
        for _ in range(size):
            self._pool.put(self._make_connection())

    def _make_connection(self):
        return pymysql.connect(
            host=db_host, port=3306, user=db_username, password=db_password,
            database=db_name, charset="utf8mb4", cursorclass=pymysql.cursors.DictCursor
        )

    def acquire(self):
        """Check out a connection. Blocks if all connections are in use."""
        conn = self._pool.get()
        try:
            conn.ping(reconnect=True)  # Reconnect automatically if connection went stale
        except Exception:
            conn = self._make_connection()
        return conn

    def release(self, conn):
        """Return a connection to the pool."""
        self._pool.put(conn)

    def close_all(self):
        """Close every connection in the pool (call on bot shutdown)."""
        while not self._pool.empty():
            conn = self._pool.get_nowait()
            try:
                conn.close()
            except Exception:
                pass


_pool = ConnectionPool(POOL_SIZE)

# Semaphore is created lazily on first use — asyncio requires it to be
# instantiated inside the running event loop, not at module import time.
_db_semaphore = None

def _get_semaphore():
    global _db_semaphore
    if _db_semaphore is None:
        _db_semaphore = asyncio.Semaphore(POOL_SIZE)
    return _db_semaphore


class Database:
    """
    Provides static methods to handle common database operations.

    Methods:
        delete(query, values=None): Execute a DELETE SQL command.
        insert(query, values=None, many_entities=False): Execute an INSERT SQL command.
        select(query, values=None, fetch=True): Execute a SELECT SQL command and optionally fetch results.
        update(query, values=None): Execute an UPDATE SQL command.
    """

    def connect(self, close_connection=False):
        """
        Establishes a connection to the database using predefined environment variables.

        Args:
            close_connection (bool): If True, the connection will be closed immediately after being established.

        Returns:
            The database connection object if close_connection is False, otherwise True on successful connection.

        Raises:
            ConnectionError: If the connection to the database fails.
        """
        try:
            conn = pymysql.connect(host=db_host, port=3306, user=db_username, password=db_password,
                                   database=db_name, charset="utf8mb4", cursorclass=pymysql.cursors.DictCursor)
            print(f"Connected to database {db_name}")
            return conn if not close_connection else True
        except ConnectionError as err:
            print(f"Failed to connect to the database: {err}")
            if close_connection:
                conn.close()
            raise


    def get_response(self, query, values=None, fetch=False, many_entities=False, type=None):
        """
        Executes a SQL query with optional values and fetches results if requested.

        Args:
            query (str): SQL query string to be executed.
            values (tuple, optional): Parameters to be used with the query.
            fetch (bool): If True, fetches and returns the query results.
            many_entities (bool): If True, executes the query for many records.

        Returns:
            The result of the query if fetch is True; None otherwise.
        """
        connection = _pool.acquire()
        cursor = connection.cursor(pymysql.cursors.DictCursor)
        try:
            if type == "Proc":
                cursor.callproc(query, values or ())
            else:
                if values:
                    if many_entities:
                        cursor.executemany(query, values)
                    else:
                        cursor.execute(query, values)
                else:
                    cursor.execute(query)

            if fetch:
                return cursor.fetchall()
        finally:
            connection.commit()
            cursor.close()
            _pool.release(connection)  # Return connection to pool instead of closing it

    @staticmethod
    def select(query, values=None, fetch=True):
        return Database().get_response(query, values=values, fetch=fetch)

    @staticmethod
    def insert(query, values=None, many_entities=False):
        return Database().get_response(query, values=values, many_entities=many_entities)

    @staticmethod
    def update(query, values=None):
        return Database().get_response(query, values=values)

    @staticmethod
    def delete(query, values=None):
        return Database().get_response(query, values=values)

    @staticmethod
    def callprocedure(sql_stored_component, parameters=None, fetch=False):
        return Database().get_response(sql_stored_component, values=parameters, type="Proc", fetch=fetch)

    # --- Async wrappers (run blocking DB calls on a background thread) ---
    # Each wrapper acquires the semaphore before scheduling work on the executor.
    # This caps the number of concurrent DB operations to POOL_SIZE, ensuring
    # threads never compete for a connection that isn't available in the pool.

    @staticmethod
    async def select_async(query, values=None, fetch=True):
        async with _get_semaphore():
            loop = asyncio.get_running_loop()
            return await loop.run_in_executor(_executor, lambda: Database.select(query, values, fetch))

    @staticmethod
    async def insert_async(query, values=None, many_entities=False):
        async with _get_semaphore():
            loop = asyncio.get_running_loop()
            return await loop.run_in_executor(_executor, lambda: Database.insert(query, values, many_entities))

    @staticmethod
    async def update_async(query, values=None):
        async with _get_semaphore():
            loop = asyncio.get_running_loop()
            return await loop.run_in_executor(_executor, lambda: Database.update(query, values))

    @staticmethod
    async def delete_async(query, values=None):
        async with _get_semaphore():
            loop = asyncio.get_running_loop()
            return await loop.run_in_executor(_executor, lambda: Database.delete(query, values))

    @staticmethod
    async def callprocedure_async(sql_stored_component, parameters=None, fetch=False):
        async with _get_semaphore():
            loop = asyncio.get_running_loop()
            return await loop.run_in_executor(_executor, lambda: Database.callprocedure(sql_stored_component, parameters, fetch))

class Query:

    REGISTERED_USER = """
        SELECT * FROM RegisteredUsers
        WHERE tracking_id = %s
    """

    INSERT_REGISTERED_USER = """
        INSERT INTO RegisteredUsers (tracking_id, email, first_name, last_name, role_id)
        VALUES (%(tracking_id)s, %(email)s, %(first_name)s, %(last_name)s, %(role_id)s)
    """

    CHECK_NUM_PROPERTIES = """
        SELECT COUNT(pp.property_id) AS property_count
        FROM UserPortfolios up
        JOIN PortfolioProperties pp
            ON up.portfolio_id = pp.portfolio_id
        WHERE up.user_id = %s
    """

    DELETE_REGISTERED_USER = """
        DELETE FROM RegisteredUsers
        WHERE tracking_id = %s
    """

    DELETE_USER_PORTFOLIO = """
        DELETE FROM UserPortfolios
        WHERE user_id = %s
    """

    DELETE_USER_PROJECT_CONTRACTORS = """
        DELETE pc FROM ProjectContractors pc
        JOIN Contractors c ON pc.contractor_id = c.tracking_id
        WHERE c.user_id = %s
    """

    DELETE_USER_CONTRACTORS = """
        DELETE FROM Contractors WHERE user_id = %s
    """

    PORTFOLIO_PERFORMANCE_BY_USER = """
        SELECT *
        FROM PortfolioPerformance
        WHERE User_ID = %s
        ORDER BY cash_flow ASC
    """

    TENANTS_BY_USER = """
        SELECT *
        FROM ViewTenants
        WHERE user_id = %s
        ORDER BY past_due_balance DESC
    """

    MORTGAGES_BY_USER = """
        SELECT *
        FROM ViewMortgages
        WHERE user_id = %s
        ORDER BY mortgage_id IS NULL, start_date ASC
    """

    CURRENT_PROJECTS_BY_USER = """
        SELECT *
        FROM CurrentProjects
        WHERE user_id = %s
        ORDER BY in_progress DESC, numbered_street ASC
    """

    PROC_AssignRole = """AssignRole"""
    PROC_CheckBeforeQuery = """CheckBeforeQuery"""
    PROC_RefreshRole = """RefreshRole"""
    PROC_CreateSampleUserData = """CreateSampleUserData"""
    PROC_ResetUserData = """ResetUserData"""
    PROC_CleanOrphanedData = """CleanOrphanedData"""
    PROC_GetPortfolioPerformance = """GetPortfolioPerformance"""
    PROC_GetTenants = """GetTenants"""
    PROC_GetMortgages = """GetMortgages"""
    PROC_GetCurrentProjects = """GetCurrentProjects"""
    

class Tables:
    # TODO: Create here all the constants for your table descriptors

    # Tables
    ADDRESSES = "Addresses"
    CONTRACTORS = "Contractors"
    EXPENSE_HISTORIES = "ExpenseHistories"
    INSPECTION_RECORDS = "InspectionRecords"
    INSURANCE_POLICIES = "InsurancePolicies"
    LEASE_AGREEMENTS = "LeaseAgreements"
    MORTGAGES = "Mortgages"
    PAYMENT_HISTORIES = "PaymentHistories" 
    PORTFOLIO_PROPERTIES = "PortfolioProperties"
    PORTFOLIOS = "Portfolios"
    PROJECT_CONTRACTORS = "ProjectContractors"
    PROJECT_INFOS = "ProjectInfos"
    PROJECT_UPDATES = "ProjectUpdates"
    PROPERTIES = "Properties"
    PROPERTY_HISTORIES = "PropertyHistories"
    REGISTERED_USERS = "RegisteredUsers"
    ROLES = "Roles"
    TAX_RECORDS = "TaxRecords"
    TENANTS = "Tenants"
    UNITS = "Units"
    UNIT_TENANTS = "UnitTenants"
    USER_PORTFOLIOS = "UserPortfolios"

    # Views
    CURRENT_PROJECTS = "CurrentProjects"
    PORTFOLIO_PERFORMANCE = "PortfolioPerformance"
    VIEW_MORTGAGES = "ViewMortgages" 
    VIEW_TENANTS = "ViewTenants" 
    