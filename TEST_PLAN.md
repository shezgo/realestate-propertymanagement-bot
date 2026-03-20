# Test Plan — Real Estate Property Management Bot

## Scope
This plan covers automated testing of the Python backend for the Discord-based
property management bot. It covers the database access layer, data models, and
stored procedure behavior.

---

## Test Objectives
- Verify business logic in the model layer behaves correctly independent of the database
- Verify database procedures produce the expected state changes
- Ensure the system handles missing or malformed data without crashing
- Provide a regression safety net for future changes to models or queries

---

## Test Categories

### Unit Tests (`pytest -m unit`)
Run offline. No database required. Use mocked dependencies.

| Test | What it validates |
|---|---|
| `test_load_maps_fields_correctly` | RegisteredUserModel correctly maps all DB row fields to attributes |
| `test_load_handles_empty_result` | Model stays at default None values when DB returns no rows |
| `test_load_handles_none_result` | Model does not raise when DB returns None instead of an empty list |
| `test_make_registered_user_calls_insert` | ModelFactory.make triggers exactly one DB insert for REGISTERED_USERS |
| `test_make_registered_user_passes_correct_data` | ModelFactory forwards the correct data dict to Database.insert |

### Integration Tests (`pytest -m integration`)
Require a live MySQL connection. Run against real database with test data isolated
under a dedicated test user ID (12340) that is created and deleted per test.

| Test | What it validates |
|---|---|
| `test_register` | Inserted user is persisted and retrievable with all correct field values |
| `test_create_sample` | CreateSampleUserData procedure adds exactly 6 properties to the user portfolio |
| `test_reset_user_data` | ResetUserData procedure removes exactly the 6 properties added by CreateSampleUserData |

---

## Test Isolation Strategy
- Each integration test receives a fresh user via the `registered_test_user` pytest fixture
- Fixture teardown deletes the test user and portfolio after every test, regardless of pass or fail
- Unit tests use `unittest.mock.patch` to replace database calls, ensuring no real connections are made

---

## Entry Criteria
- All dependencies installed (`pip install -r requirements.txt`)
- For integration tests: environment variables set for DB_HOST, DB_USER, DB_PASSWORD, DB_NAME

## Exit Criteria
- All unit tests pass in CI on every push to `main`
- All integration tests pass before any release

---

## Out of Scope
- Discord API behavior and bot command responses (would require Discord API mocking)
- Frontend/UI testing (Discord client)
- Load and performance testing
- The MySQL schema itself (stored procedures, views, triggers)
