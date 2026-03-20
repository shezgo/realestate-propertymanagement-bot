import pytest
from unittest.mock import patch
from models import RegisteredUserModel, ModelFactory, Tables


@pytest.mark.unit
class TestRegisteredUserModel:

    def test_load_maps_fields_correctly(self):
        # Verifies the model reads and assigns every field from the DB row properly.
        # patch replaces Database.select with a fake that returns one controlled row,
        # so we're testing the mapping logic in _load(), not the database.
        fake_row = {
            "email": "jane@example.com",
            "first_name": "Jane",
            "last_name": "Doe",
            "full_name": "Jane Doe",
            "role_id": 2,
            "role_expires": None,
            "has_sample_data": False
        }
        with patch("models.Database.select", return_value=[fake_row]):
            user = RegisteredUserModel(99999)

        assert user.email == "jane@example.com"
        assert user.first_name == "Jane"
        assert user.last_name == "Doe"
        assert user.full_name == "Jane Doe"
        assert user.role_id == 2

    def test_load_handles_empty_result(self):
        # Edge case: DB finds no matching user.
        # Model attributes should stay at their default None values — no crash, no partial data.
        with patch("models.Database.select", return_value=[]):
            user = RegisteredUserModel(99999)

        assert user.email is None
        assert user.role_id is None

    def test_load_handles_none_result(self):
        # Defensive case: DB returns None instead of an empty list.
        # _load() guards against this with "if not data: return" — this test verifies that guard works.
        with patch("models.Database.select", return_value=None):
            user = RegisteredUserModel(99999)

        assert user.email is None


@pytest.mark.unit
class TestModelFactory:

    def test_make_registered_user_calls_insert(self):
        # Verifies ModelFactory.make actually triggers a DB insert for REGISTERED_USERS.
        # mock_insert.assert_called_once() fails if insert was skipped or called more than once.
        data = {
            "tracking_id": 99999,
            "email": "test@example.com",
            "first_name": "Test",
            "last_name": "User",
            "role_id": 1
        }
        with patch("models.Database.insert") as mock_insert, \
             patch("models.Database.select", return_value=[data]):
            ModelFactory.make(Tables.REGISTERED_USERS, data)

        mock_insert.assert_called_once()

    def test_make_registered_user_passes_correct_data(self):
        # Verifies the correct data dict reaches Database.insert unchanged.
        # mock_insert.call_args holds the arguments from the last call to the mock,
        # letting us inspect exactly what was passed without touching the real DB.
        data = {
            "tracking_id": 99999,
            "email": "test@example.com",
            "first_name": "Test",
            "last_name": "User",
            "role_id": 1
        }
        with patch("models.Database.insert") as mock_insert, \
             patch("models.Database.select", return_value=[data]):
            ModelFactory.make(Tables.REGISTERED_USERS, data)

        _, kwargs = mock_insert.call_args
        assert kwargs["values"] == data
