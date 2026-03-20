import pytest
from database import Database, Query

TEST_USER_ID = 12340

@pytest.fixture()
def registered_test_user():

    # --- setup ---
    # Delete contractor-linked data first — these are linked directly to the user
    # and not reachable via UserPortfolios, so ResetUserData cannot find them
    # if UserPortfolios was already deleted in a prior failed run.
    Database.delete(Query.DELETE_USER_PROJECT_CONTRACTORS, (TEST_USER_ID,))
    Database.delete(Query.DELETE_USER_CONTRACTORS, (TEST_USER_ID,))
    # Reset all portfolio-linked sample data
    Database.callprocedure(Query.PROC_ResetUserData, (TEST_USER_ID,))
    Database.callprocedure(Query.PROC_CleanOrphanedData)
    # Remove the portfolio link and user record
    Database.delete(Query.DELETE_USER_PORTFOLIO, (TEST_USER_ID,))
    Database.delete(Query.DELETE_REGISTERED_USER, (TEST_USER_ID,))
    Database.insert(Query.INSERT_REGISTERED_USER, {
        "tracking_id": TEST_USER_ID,
        "email": "test@email.com",
        "first_name": "First_name",
        "last_name": "Last_name",
        "role_id": 1
    })

    yield TEST_USER_ID

    # --- teardown (always runs) ---
    # Same order as setup — contractors first, then portfolio data, then user.
    Database.delete(Query.DELETE_USER_PROJECT_CONTRACTORS, (TEST_USER_ID,))
    Database.delete(Query.DELETE_USER_CONTRACTORS, (TEST_USER_ID,))
    Database.callprocedure(Query.PROC_ResetUserData, (TEST_USER_ID,))
    Database.callprocedure(Query.PROC_CleanOrphanedData)
    Database.delete(Query.DELETE_USER_PORTFOLIO, (TEST_USER_ID,))
    Database.delete(Query.DELETE_REGISTERED_USER, (TEST_USER_ID,))
