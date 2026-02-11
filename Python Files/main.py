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
        response = "Hello, from your Bot. I am alive!1. \n"
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

@bot.command(name = "register", help = "Use this command to create an account for your " 
                                        "property management database")
async def register_user(ctx, email: str, first_name: str, last_name: str):
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

    
    Database.insert(Query.INSERT_REGISTERED_USER, (discord_id, email, first_name, last_name))

    await ctx.send(f"Welcome, {first_name}! Your Discord ID has been securely linked to your account.")

bot.run(TOKEN)

