"""
IMPORTANT: Database logic must not be implemented directly in this file. Ensure all database interactions
are handled in separate, designated files to maintain a clean separation of concerns.

"""

import os
import discord
from discord.ext import commands
from models import *

# Add your Discord bot token to your project's environment variables using the secret key: 'DISCORD_TOKEN'
TOKEN = os.environ["DISCORD_TOKEN"]

# Setting up the bot with necessary intents to handle events and commands
intents = discord.Intents.all()  # Adjust the intents according to your bot's needs


# Custom Help Command

class CustomHelpCommand(commands.DefaultHelpCommand):
    async def send_bot_help(self, mapping):
        await self.get_destination().send(
            "**Real Estate Property Management Bot**\n"
            "Use `!` as a prefix before every command — e.g. `!register`, `!portfolio_performance`.\n"
            "─────────────────────────────────────────"
        )
        await super().send_bot_help(mapping)


# Bot Setup 

bot = commands.Bot(
    command_prefix='!',
    intents=intents,
    help_command=CustomHelpCommand()
)


# Cogs 

class Setup(commands.Cog, name="Setup"):
    """Commands for account setup and data management."""

    def __init__(self, bot):
        self.bot = bot

    # Test command to be used to check if your bot is online.
    @commands.command(name="test_bot", help="Test bot connection")
    async def test_bot(self, ctx, with_db_conn=None):
        """
        Usage:
          (1) To test the bot without a database connection: !test_bot
          (2) To test the bot with a database connection: !test_bot db_connect
        """
        try:
            response = "Hello, from your Bot. I am alive! \n"
            if with_db_conn and "db_connect" in with_db_conn:
                from database import Database  # only imported in this scope
                db = Database()
                if db.connect():
                    response = response + "The connection to the database has been established."
        except RuntimeError as err:
            response = ("An error has occurred. The following are the possible causes: \n (1) If your bot is offline, "
                        "then check if your TOKEN credentials provided in your secrets match with your bot TOKEN. \n (2) "
                        "If your bot is online but not connected to the database check if your secrets provided match "
                        "with the ones provided by your remote database cloud instance (i.e AWS RDS Instance). If your "
                        "secrets are correct, check if your Ipv4 inbounds are open in your cloud instance for the port "
                        "reserved to databases 3306")
            print(f"This is the error message printed in console for more details: {err.args[1]}")
        await ctx.send(response)

    @commands.command(name="register", help="Create your real estate property management DB account.")
    async def register_user(self, ctx, email=None, first_name=None, last_name=None):
        discord_id = ctx.author.id

        existing_user = Database.select(Query.REGISTERED_USER, (discord_id,))

        if existing_user:
            await ctx.send("You are already registered in the system.")
            return

        await ctx.send("Let's get you registered.\n"
                       "Please enter your email:")

        def check(msg):
            return msg.author == ctx.author and msg.channel == ctx.channel

        try:
            email_msg = await self.bot.wait_for("message", timeout=60.0, check=check)
            email = email_msg.content.strip()

            await ctx.send("Please enter your first name:")
            first_name_msg = await self.bot.wait_for("message", timeout=60.0, check=check)
            first_name = first_name_msg.content.strip()

            await ctx.send("Please enter your last name:")
            last_name_msg = await self.bot.wait_for("message", timeout=60.0, check=check)
            last_name = last_name_msg.content.strip()

        except:
            await ctx.send("Registration timed out. Please try again.")
            return

        new_user = {
            "tracking_id": discord_id,
            "email": email,
            "first_name": first_name,
            "last_name": last_name,
            "role_id": 1  # All users are owners for now.
        }
        registered_user = ModelFactory.make(Tables.REGISTERED_USERS, new_user)

        await ctx.send(f"Welcome, {registered_user.first_name}! Your Discord ID has been securely linked to your account.")

    @commands.command(name="create_sample", help="Create sample data set in your account for testing.")
    async def create_sample_data(self, ctx):
        discord_id = ctx.author.id

        existing_user = Database.select(Query.REGISTERED_USER, (discord_id,))

        if not existing_user:
            print("Account needed to create sample data - use !register to create an account.")
            return

        Database.callprocedure(Query.PROC_CreateSampleUserData, (discord_id,))

        await ctx.send(f"Sample data has been created for {getBy(Tables.REGISTERED_USERS, discord_id).full_name}")

    @commands.command(name="reset_user_data", help="Reset your data — clears all contents associated with your portfolio.")
    async def reset_user_data(self, ctx):
        discord_id = ctx.author.id
        await ctx.send("Are you sure you want to reset your data? (y/n)")

        def check(msg):
            return msg.author == ctx.author and msg.channel == ctx.channel

        try:
            response_msg = await self.bot.wait_for("message", timeout=60.0, check=check)
            if response_msg.content.lower() == 'y':
                Database.callprocedure(Query.PROC_ResetUserData, (discord_id,))
                await ctx.send("User portfolio and associated contents have been reset.")
            else:
                await ctx.send("Reset cancelled.")

        except:
            await ctx.send("Timed out. Please try again.")
            return


class Portfolio(commands.Cog, name="Portfolio"):
    """Commands for viewing portfolio data."""

    def __init__(self, bot):
        self.bot = bot

    @commands.command(name="portfolio_performance", help="View your portfolio properties ordered by cash flow (lowest first).")
    async def portfolio_performance(self, ctx):
        discord_id = ctx.author.id

        existing_user = Database.select(Query.REGISTERED_USER, (discord_id,))

        if not existing_user:
            await ctx.send("You need to be registered to view portfolio performance. Use !register to create an account.")
            return

        performance = PortfolioPerformanceModel(discord_id)

        if not performance.rows:
            await ctx.send("No portfolio data found. Use !create_sample to add sample data.")
            return

        await ctx.send("**Portfolio Performance** — ordered by cash flow (worst to best):\n")

        for i, row in enumerate(performance.rows, 1):
            mortgage  = row.get("Mortgage") or 0
            capex     = row.get("Capital_Expenditures") or 0
            cash_flow = row.get("cash_flow") or 0
            entry = (
                f"**#{i} — {row.get('Address', 'N/A')}**\n"
                f"  Property ID:    {row.get('Property_ID')}\n"
                f"  Rental Income:  ${row.get('Rental_Income', 0):,.2f}\n"
                f"  Mortgage:       ${mortgage:,.2f}\n"
                f"  CapEx:          ${capex:,.2f}\n"
                f"  Cash Flow:      ${cash_flow:,.2f}\n"
                f"  Purchase Price: ${row.get('Purchase_Price', 0):,.2f}\n"
                f"  ARV:            ${row.get('ARV', 0):,.2f}\n"
            )
            await ctx.send(entry)

    @commands.command(name="view_tenants", help="View all tenants in your portfolio ordered by past due balance (highest first).")
    async def view_tenants(self, ctx):
        discord_id = ctx.author.id

        existing_user = Database.select(Query.REGISTERED_USER, (discord_id,))

        if not existing_user:
            await ctx.send("You need to be registered to view tenants. Use !register to create an account.")
            return

        tenants = ViewTenantsModel(discord_id)

        if not tenants.rows:
            await ctx.send("No tenant data found. Use !create_sample to add sample data.")
            return

        await ctx.send("**Tenants** — ordered by past due balance (highest first):\n")

        for i, row in enumerate(tenants.rows, 1):
            past_due = row.get("past_due_balance") or 0
            entry = (
                f"**#{i} — {row.get('tenant_name', 'N/A')}**\n"
                f"  Tenant ID:        {row.get('tenant_id')}\n"
                f"  Unit ID:          {row.get('unit_id')}\n"
                f"  Property Address: {row.get('property_address', 'N/A')}\n"
                f"  Past Due Balance: ${past_due:,.2f}\n"
            )
            await ctx.send(entry)

    @commands.command(name="view_mortgages", help="View all mortgages in your portfolio ordered by start date.")
    async def view_mortgages(self, ctx):
        discord_id = ctx.author.id

        existing_user = Database.select(Query.REGISTERED_USER, (discord_id,))

        if not existing_user:
            await ctx.send("You need to be registered to view mortgages. Use !register to create an account.")
            return

        mortgages = ViewMortgagesModel(discord_id)

        if not mortgages.rows:
            await ctx.send("No mortgage data found. Use !create_sample to add sample data.")
            return

        await ctx.send("**Mortgages** — ordered by start date (totals row last):\n")

        for row in mortgages.rows:
            is_totals = row.get("mortgage_id") is None
            if is_totals:
                entry = (
                    f"**— Totals —**\n"
                    f"  Total Principal Balance: ${row.get('principal_balance', 0):,.2f}\n"
                    f"  Total Monthly Payment:   ${row.get('monthly_payment', 0):,.2f}\n"
                    f"  Total Purchase Price:    ${row.get('purchase_price', 0):,.2f}\n"
                )
            else:
                entry = (
                    f"**{row.get('lender_name', 'N/A')}** (ID: {row.get('mortgage_id')})\n"
                    f"  Property:          {row.get('property_address', 'N/A')}\n"
                    f"  Principal Balance: ${row.get('principal_balance', 0):,.2f}\n"
                    f"  Interest Rate:     {row.get('interest_rate', 0)}%\n"
                    f"  Monthly Payment:   ${row.get('monthly_payment', 0):,.2f}\n"
                    f"  Term:              {row.get('start_date')} → {row.get('end_date')}\n"
                    f"  Purchase Price:    ${row.get('purchase_price', 0):,.2f}\n"
                )
            await ctx.send(entry)

    @commands.command(name="view_projects", help="View all projects in your portfolio, in-progress projects first.")
    async def view_projects(self, ctx):
        discord_id = ctx.author.id

        existing_user = Database.select(Query.REGISTERED_USER, (discord_id,))

        if not existing_user:
            await ctx.send("You need to be registered to view projects. Use !register to create an account.")
            return

        projects = CurrentProjectsModel(discord_id)

        if not projects.rows:
            await ctx.send("No project data found. Use !create_sample to add sample data.")
            return

        await ctx.send("**Current Projects** — in-progress first:\n")

        for i, row in enumerate(projects.rows, 1):
            status = "In Progress" if row.get("in_progress") else "Not In Progress"
            entry = (
                f"**#{i} — {row.get('numbered_street', 'N/A')}, {row.get('city', 'N/A')}**\n"
                f"  Project:     {row.get('project', 'N/A')}\n"
                f"  Status:      {status}\n"
                f"  Description: {row.get('project_description', 'N/A')}\n"
                f"  Contractor:  {row.get('contractor', 'N/A')} ({row.get('contractor_company', 'N/A')})\n"
                f"  Services:    {row.get('services', 'N/A')}\n"
            )
            await ctx.send(entry)


# Register Cogs & Run

async def setup_hook():
    await bot.add_cog(Setup(bot))
    await bot.add_cog(Portfolio(bot))

bot.setup_hook = setup_hook

bot.run(TOKEN)
