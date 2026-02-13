# Discord API has a limited number of requests (bot requests) per day.
# If developers meet that quota, then Discord will put a temporal ban to your bot (24 hours)
# In order to avoid that, and only for testing, create unit test methods to test your functions
# without using the functionality provided by your bot. Once all your tests passed, then you can
# integrate these functions with your bot logic in main.py

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

