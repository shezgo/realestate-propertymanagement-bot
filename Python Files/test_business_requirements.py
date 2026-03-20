import pytest
from models import *

@pytest.mark.integration
def test_register(registered_test_user):
    """User inserted by fixture should be retrievable with correct fields."""
    user = Database.select(Query.REGISTERED_USER, (registered_test_user,))

    assert user is not None and len(user) == 1
    row = user[0]
    assert row["tracking_id"] == registered_test_user
    assert row["email"] == "test@email.com"
    assert row["first_name"] == "First_name"
    assert row["last_name"] == "Last_name"
    assert row["role_id"] == 1


@pytest.mark.integration
def test_create_sample(registered_test_user):
    """CreateSampleUserData procedure should add exactly 6 properties."""
    before = Database.select(Query.CHECK_NUM_PROPERTIES, (registered_test_user,))
    before_count = before[0]["property_count"] if before else 0

    Database.callprocedure(Query.PROC_CreateSampleUserData, (registered_test_user,))

    after = Database.select(Query.CHECK_NUM_PROPERTIES, (registered_test_user,))
    after_count = after[0]["property_count"] if after else 0

    assert after_count == before_count + 6, \
        f"Expected +6 properties, got {after_count - before_count}"


@pytest.mark.integration
def test_reset_user_data(registered_test_user):
    """ResetUserData procedure should remove all properties added by CreateSampleUserData."""
    Database.callprocedure(Query.PROC_CreateSampleUserData, (registered_test_user,))
    before = Database.select(Query.CHECK_NUM_PROPERTIES, (registered_test_user,))
    before_count = before[0]["property_count"] if before else 0

    Database.callprocedure(Query.PROC_ResetUserData, (registered_test_user,))
    Database.callprocedure(Query.PROC_CleanOrphanedData)

    after = Database.select(Query.CHECK_NUM_PROPERTIES, (registered_test_user,))
    after_count = after[0]["property_count"] if after else 0

    assert after_count == before_count - 6, \
        f"Expected -6 properties, got {after_count - before_count}"
