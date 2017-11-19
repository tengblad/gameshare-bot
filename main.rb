#!/usr/bin/ruby

require 'rubygems'
require 'discordrb'
require 'sequel'
require 'logger'

@logger = Logger.new('logfile.log')

@logger.info("Starting application")

DB = Sequel.connect('sqlite://games.db') # requires sqlite3

DB.create_table? :names do
  String :name
  unique(:name)
  primary_key [:name]
end

DB.create_table? :keys do
  String :names_name
  String :key
  unique(:key)
  foreign_key [:names_name], :names
end

names = DB[:names].order(:name)
keys  = DB[:keys].order(:names_name)


@niceWords = ["swell", "cute", "nice", "adorable", "good-hearted", "lovely", "amazing", "awesome", "fantastic", "wonderful", "adorable", "ghostly", "pink", "purrfect", "supercalifragilisticexpialidocious", "thoughtful", "charming", "generous", "good", "helpful", "neat", "plucky", "sweet"]


bot = Discordrb::Commands::CommandBot.new token: 'MzY3NjYyOTE5ODA4NDUwNTcw.DL-vNA.MzKXZi911l483d3ngX4yEurYeAI', client_id: 367662919808450570, prefix: '!', advanced_functionality: true

#bot.send_message('321728273501519873', "Hello! I'm a friendly game sharing bot! Send me '!help' or '!gamekeys' in a private message to learn more!")

bot.message(with_text: '!cat') do |event|
  event.respond "I'm not a cat! I'm a person! >:3"
end


bot.command(:gamekeys, description: "General information about the bot") do |gamekeys|
  gamekeys.user.pm "Hello! Welcome to the game key share bot!"
  gamekeys.user.pm "To learn how to use this bot, type !help"
end


bot.command(:list, description: "List all the games with keys in the database", usage: "!list") do |list|
  game_names = keys.select_map(:names_name).to_a
  game_names = game_names.uniq
  games_chunks = game_names.each_slice(75)

  list.user.pm "The database contains keys for the following games:" "\n#{@game_list}"
  games_chunks.each do |games|
       game_list = ''
       games.each do |name|
         game_list << name + "\n"
       end
      list.user.pm "#{game_list}"
  end
  return 0
end

bot.command(:add, min_args: 2, max_args: 2, description: "Add a game key.", usage: "!add \"[game name]\" \"[game key]\". Note that if the game name or key contain spaces they  must be within quotation marks! Also, if your key is a Humble Gift, or any other weblink, drop the http:// at the start of the URL!") do |_event, game, key|
  @user = _event.user.name 
  if names.where(:name => game).empty?
    names.insert(:name => game)
    if keys.where(:key => key).empty?
      keys.insert(:key => key, :names_name => game)
      @logger.info("Key #{key} for game #{game} was added by #{@user}")
      _event.user.pm "Added key #{key} for game #{game} to database."
      bot.send_message('193098277984403456', "#{@user} added a key for #{game}. They're so #{@niceWords.sample}!")
 #     bot.send_message('277122727847002113', "#{@user} added a key for #{game}.")
    else 
      _event.user.pm "Key #{key} already exists in database."
    end
  else
    if keys.where(:key => key).empty?
      keys.insert(:key => key, :names_name => game)
      @logger.info("Key #{key} for game #{game} was added by #{@user}")
      _event.user.pm "Added key #{key} for game #{game} to database."
      bot.send_message('193098277984403456', "#{@user} added a key for #{game}. They're so #{@niceWords.sample}!")
#      bot.send_message('277122727847002113', "#{@user} added a key for #{game}.")
    else
      _event.user.pm "Key #{key} already exists in database."
    end

  end
end

bot.command(:claim, min_args: 1, max_args: 1, description: "Claim a game key", usage: "!claim \"[game name]\". Note that the game contains spaces it must be whithin quotation marks!") do |event, game| 
  @user = event.user.name
  if keys.where(:names_name => game).empty?
    event.user.pm "No unclaimed keys for game #{game} found."
    break
  end

  result = keys.where(:names_name => game).first
  key = result[:key]

  event.user.pm "Here is your key for the game #{game}: #{key}. Please enjoy!"

  #event.user.pm "Deleting key from database"
  keys.where(:key => key).delete
  #event.user.pm "Key has been deleted"
  bot.send_message('277122727847002113', "<@#{event.user.id}> claimed key #{key} for #{game}.")

  @logger.info("Key #{key} for game #{game} was claimed by #{@user}")
  return 0
end
bot.run
