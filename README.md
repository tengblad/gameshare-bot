# gameshare-bot
A Discord bot for distributing Steam, Origin and other types of game keys

## Installation
Installing is as simple as cloning the git repo and then running bundle install
``git clone https://github.com/tengblad/gameshare-bot.git
cd gameshare-bot
bundle install``

## Configuration
Before you run the bot you should copy config.template.yaml to confing.yaml, and then edit the config. The token and clientIds should be self-explanatory enough. ``auditChannel`` should define which channel the bot should post audit messages to (currently only who took a key), and ``announcementChannel`` should be set with the id of the channel where the bot should announce that a new key has been added.

## Running the bot
The easiest way to start the bot is to use the inclued ``gameshareBot.sh`` script.

## Usage
The following commands are supported by the bot:
!help: Shows a list of all the commands available or displays help for a specific command.
!gamekeys: General information about the bot
!list: List all the games with keys in the database
!add: Add a game key.
!claim: Claim a game key
