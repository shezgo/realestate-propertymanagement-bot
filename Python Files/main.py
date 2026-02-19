"""
The code provided below serves as a basic framework for implementing a Discord bot.
It is intended to guide students in developing a bot that meets the specific requirements of their projects.

IMPORTANT: Database logic must not be implemented directly in this file. Ensure all database interactions
are handled in separate, designated files to maintain a clean separation of concerns.

Please modify and extend this code to fit your project's specific requirements.
"""

import os
import discord
from discord.ext import commands
# from models import *

"""
The code provided below serves as a basic framework for implementing a Discord bot.
It is intended to guide students in developing a bot that meets the specific requirements of their projects.

IMPORTANT: Database logic must not be implemented directly in this file. Ensure all database interactions
are handled in separate, designated files to maintain a clean separation of concerns.

Please modify and extend this code to fit your project's specific requirements.
"""

import os
import discord
from discord.ext import commands
from models import *

# Add your Discord bot token to your project's environment variables using the secret key: 'DISCORD_TOKEN'
TOKEN = os.environ["DISCORD_TOKEN"]

# Setting up the bot with necessary intents to handle events and commands
intents = discord.Intents.all()  # Adjust the intents according to your bot's needs
# Command prefix may be changed to fit your own needs as long as it is well documented in your #commands channel.
bot = commands.Bot(command_prefix='!', intents=intents)


############################################ Bot Commands ##################################################################



# Test command to be used to check if your bot is online.
@bot.command(name="test_bot", help="Use this command to test if your bot is making requests and receiving responses "
                                   "from your backend service")
async def test_bot(ctx, with_db_conn=None):
    """
    Note: This function will work only if your Bot TOKEN credential added in your secrets matches the one provided by
    your Bot application created in your Discord Developer Console. Additionally, your bot will create a connection to
    your database only if your database credentials added to your secrets for the database connection are correct and
    the 'with_db_conn' parameter is enabled.
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


# TODO: Customize further commands according to your project's requirements:
#       (1) Define the business logic requirements for each command in the help parameter.
#       (2) Implement the functionalities of these commands based on your project needs.

# Bot command to register a user's discord account with the program.
@bot.command(name = "register", help = "Use this command to create an account for your " 
                                        "property management database")
async def register_user(ctx, email = None, first_name = None, last_name = None):
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
        email_msg = await bot.wait_for("message", timeout = 60.0, check = check)
        email = email_msg.content.strip()

        await ctx.send("Please enter your first name:")
        first_name_msg = await bot.wait_for("message", timeout = 60.0, check = check)
        first_name = first_name_msg.content.strip()

        await ctx.send("Please enter your last name:")
        last_name_msg = await bot.wait_for("message", timeout = 60.0, check = check)
        last_name = last_name_msg.content.strip()

    except:
        await ctx.send("Registration timed out. Please try again.")
        return

    new_user ={
        "tracking_id": discord_id,
        "email": email,
        "first_name": first_name,
        "last_name": last_name,
        "role_id": 1 # All users are owners for now.
    }
    registered_user = ModelFactory.make(Tables.REGISTERED_USERS, new_user)

    await ctx.send(f"Welcome, {registered_user.first_name}! Your Discord ID has been securely linked to your account.")

@bot.command(name="create_sample", help = "Use this command to create a set of sample" 
                                                "data in your account for testing.")
async def create_sample_data(ctx):
    discord_id = ctx.author.id 

    existing_user = Database.select(Query.REGISTERED_USER, (discord_id,))
    
    if not existing_user:
        print("Account needed to create sample data - use !register to create an account.")
        return
    
    Database.callprocedure(Query.PROC_CreateSampleUserData, (discord_id,))

    await ctx.send(f"Sample data has been created for {ModelFactory.getBy(Tables.REGISTERED_USERS,
                                                                           discord_id).full_name}")
    
@bot.command(name="reset_user_data", help = "Use this command to reset your data - this will clear all associated" \
                                        "contents with your portfolio.")
async def reset_user_data(ctx):
    discord_id = ctx.author.id
    await ctx.send("Are you sure you want to reset your data? (y/n)")

    def check(msg):
        return msg.author == ctx.author and msg.channel == ctx.channel

    try:
        response_msg = await bot.wait_for("message", timeout = 60.0, check = check)
        if response_msg.content.lower == 'y':
            Database.callprocedure(Query.PROC_ResetUserData, (discord_id,))
            await ctx.send("User portfolio and associated contents have been reset.") 

    
    except:
        await ctx.send("Timed out. Please try again.")
        return
    
    




bot.run(TOKEN)

