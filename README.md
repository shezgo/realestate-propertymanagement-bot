# Real Estate Property Management Bot

A Discord bot for managing real estate portfolios. Property owners can register an account, view portfolio performance, track tenants, monitor mortgages, and manage renovation projects — all from within a Discord server.

---

## How It Works

The bot connects to a MySQL database and a Discord server. Each user links their Discord account to a profile in the database via the `!register` command. Once registered, users can run commands to view and manage their property data.

All commands use the `!` prefix (e.g., `!portfolio_performance`). The bot responds directly in the Discord channel where the command was sent.

**Tech stack:**
- Python + discord.py
- MySQL (hosted on AWS RDS)
- pymysql for database connections

**To run the bot locally:**
1. Clone the repository
2. Install dependencies: `pip install discord.py pymysql python-dotenv`
3. Create a `.env` file with your Discord token and database credentials (see `.env` section below)
4. Run: `python "Python Files/main.py"`

**Required `.env` variables:**
```
DISCORD_TOKEN=your_discord_bot_token
DB_HOST=your_database_host
DB_USER=your_database_user
DB_PASSWORD=your_database_password
DB_NAME=PropertyManagementDB
```

---

## Commands

---

### `!test_bot`

Tests whether the bot is online and optionally checks the database connection.

**Usage:**
- `!test_bot` — confirms the bot is running
- `!test_bot db_connect` — also tests the database connection and reports success or failure

<img width="400" height="130" alt="image" src="https://github.com/user-attachments/assets/2ce0dcb5-7859-432b-8688-1d2c0b12e1b0" />


---

### `!register`

Creates a new user account linked to your Discord ID.

The bot will prompt you for:
- Your email address
- Your first name
- Your last name

Once registered, your Discord account is tied to a profile in the database and you can use all other commands. Each Discord account can only be registered once.

<img width="400" height="420" alt="image" src="https://github.com/user-attachments/assets/9d27c19a-ddb2-4dbb-9631-81683f6ea71e" />


---

### `!create_sample`

Populates your account with sample property data for testing and demonstration purposes.

Calling this command runs a stored procedure that creates 6 sample properties along with associated tenants, mortgages, units, and projects. This lets you explore all portfolio views without entering real data manually.

> Requires an active registered account (`!register` first).
<img width="400" height="100" alt="image" src="https://github.com/user-attachments/assets/5abba757-f13d-4de6-b39c-03cc75ba609a" />


---

### `!reset_user_data`

Deletes all portfolio data associated with your account.

The bot will ask you to confirm with `y` or `n` before proceeding. Once confirmed, all your properties, tenants, mortgages, units, and projects are permanently removed from the database. Your user account itself is kept.

> You have 60 seconds to respond to the confirmation prompt.

<img width="400" height="400" alt="image" src="https://github.com/user-attachments/assets/7b870785-b228-42fc-95ff-e9e7e1fd8e92" />


---

### `!portfolio_performance`

Displays a summary of all your properties and their financial performance.

Results are sorted by cash flow from lowest to highest (worst performing properties shown first).



<img width="400" height="400" alt="image" src="https://github.com/user-attachments/assets/88c58137-dd2c-42fe-ab94-f3855f7afa3e" />


---

### `!view_tenants`

Displays all tenants across your properties.

Results are sorted by past due balance from highest to lowest, so the most urgent cases appear first.



<img width="400" height="350" alt="image" src="https://github.com/user-attachments/assets/76845cec-f436-433b-9673-f67e135322ce" />


---

### `!view_mortgages`

Displays all mortgages across your properties.

Results are sorted by start date. A totals row is included at the bottom summarizing principal balance and monthly payments across all mortgages.



<img width="400" height="400" alt="image" src="https://github.com/user-attachments/assets/a3859895-e264-4791-a107-26e59534e4ea" />


---

### `!view_projects`

Displays all renovation or maintenance projects associated with your properties.

In-progress projects are shown first. Each entry includes the assigned contractor's name, company, and the services they provide.



<img width="400" height="400" alt="image" src="https://github.com/user-attachments/assets/a2bb83db-744a-4abf-9789-4e0b66cf905f" />


---

## Project Structure

```
realestate-propertymanagement-bot/
├── Python Files/
│   ├── main.py                        # Bot entry point and command handlers
│   ├── models.py                      # Data model classes
│   ├── database.py                    # Database queries and connections
│   └── test_business_requirements.py  # Unit tests
├── SQL Files/
│   ├── databasemodel.sql              # Database schema
│   ├── business_requirements.sql      # Stored procedures and triggers
│   └── inserts.sql                    # Sample data inserts
└── documentation/                     # ERD, EER diagrams and project docs
```
