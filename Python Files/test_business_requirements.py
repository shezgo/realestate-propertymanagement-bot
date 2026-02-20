# Discord API has a limited number of requests (bot requests) per day.
# These test methods are used to avoid hitting the limit during testing.

from models import *
def test_register():

    """Test the register user function from ModelFactory.make"""
    new_user ={
        "tracking_id": 12340,
        "email": 'test@email.com',
        "first_name": 'First_name',
        "last_name": 'Last_name',
        "role_id": 1 
    }
    registered_user = ModelFactory.make(Tables.REGISTERED_USERS, new_user)

    assert registered_user.tracking_id == 12340
    assert registered_user.email == 'test@email.com'
    assert registered_user.full_name == 'First_name Last_name'
    assert registered_user.role_id == 1

def test_create_sample():
    """Test the CreateSampleUserData procedure."""
    discord_id = 12340 

    existing_user = Database.select(Query.REGISTERED_USER, (discord_id,))
    
    if not existing_user:
        print("Account needed to create sample data - use !register to create an account.")
        return
    
    before_result = Database.select(Query.CHECK_NUM_PROPERTIES, (discord_id,))
    before_count = before_result[0]["property_count"] if before_result else 0

    Database.callprocedure(Query.PROC_CreateSampleUserData, (discord_id,))

    after_result = Database.select(Query.CHECK_NUM_PROPERTIES, (discord_id,))
    after_count = after_result[0]["property_count"] if after_result else 0

    assert after_count == before_count + 6, \
    f"Expected +6 properties, got {after_count - before_count}"

def test_reset_user_data():
    """Test the ResetUserData procedure."""
    discord_id = 12340
    before_result = Database.select(Query.CHECK_NUM_PROPERTIES, (discord_id,))
    before_count = before_result[0]["property_count"] if before_result else 0

    Database.callprocedure(Query.PROC_ResetUserData, (discord_id,))

    after_result = Database.select(Query.CHECK_NUM_PROPERTIES, (discord_id,))
    after_count = after_result[0]["property_count"] if after_result else 0

    assert after_count == before_count - 6, \
    f"Expected -6 properties, got {after_count - before_count}"