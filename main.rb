#!/usr/bin/ruby
require 'rubygems'
require 'discordrb'
require 'sequel'
require 'logger'
require 'yaml'

config = YAML.load_file('./config.yaml')

@token = config['token']
@clientId = config['clientId']
@auditChannel = config['auditChannel']
@announcementChannel = config['announcementChannel']

@logger = Logger.new('logfile.log')

@logger.info("Starting application")
@logger.info("Token: #{@token}")
@logger.info("ClientID: #{@clientId}")
@logger.info("Audit channel: #{@auditChannel}")
@logger.info("Announcement channel: #{@announcementChannel}")

DB = Sequel.connect('sqlite://games.db') # requires sqlite3

DB.create_table? :names do
  String :name
  unique(:name)
  primary_key [:name]
end

DB.create_table? :keys do
  String :names_name
  String :key
  String :user
  String :platform
  unique(:key)
  foreign_key [:names_name], :names
end

names = DB[:names].order(:name)
keys  = DB[:keys].order(:names_name)


@niceWords = ["swell", "cute", "nice", "adorable", "good-hearted", "lovely", "amazing", "awesome", "fantastic", "wonderful", "adorable", "ghostly", "pink", "purrfect", "supercalifragilisticexpialidocious", "thoughtful", "charming", "generous", "good", "helpful", "neat", "plucky", "sweet"]


bot = Discordrb::Commands::CommandBot.new token: @token, client_id: @clientId, prefix: '!', advanced_functionality: true

bot.send_message(@announcementChannel, "Hello! I'm a friendly game sharing bot! Send me '!help' or '!gamekeys' in a private message to learn more!")

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

bot.command(:add, min_args: 3, max_args: 3, description: "Add a game key.", usage: "!add  \"Game Name\" \"Game Key\" \"Platform (Steam/Origin/Etc)\". The bot is a little bit stupid, so if you're adding a URL as a key, please drop the http:// or https:// at the start.") do |_event, game, key, platform|
  
  @user = _event.user.name 
  if names.where(:name => game).empty?
    names.insert(:name => game)
    if keys.where(:key => key).empty?
      keys.insert(:key => key, :names_name => game, :user => @user, :platform => platform)
      @logger.info("Key #{key} for game #{game} was added by #{@user}")
      _event.user.pm "Added key #{key} for game #{game} to database."
      bot.send_message(@announcementChannel, "#{@user} added a key for #{game}. They're so #{@niceWords.sample}!")
    else 
      _event.user.pm "Key #{key} already exists in database."
    end
  else
    if keys.where(:key => key).empty?
      keys.insert(:key => key, :names_name => game, :user => @user, :platform => platform)
      @logger.info("Key #{key} for game #{game} was added by #{@user}")
      _event.user.pm "Added key #{key} for game #{game} to database."
      bot.send_message(@announcementChannel, "#{@user} added a key for #{game}. They're so #{@niceWords.sample}!")
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
  user = result[:user]
  platform = result[:platform]

  event.user.pm "Here is your #{platform} key for #{game}: #{key}."
  event.user.pm "The key was donated by #{user}. Remember to thank them!"

#  event.user.pm "Here is your key for the game #{game}: #{key} donated by user #{user}. Please enjoy!"

  keys.where(:key => key).delete
  bot.send_message(@auditChannel, "<@#{event.user.id}> claimed key #{key} for #{game}.")

  @logger.info("Key #{key} for game #{game} was claimed by #{@user}")
  return 0
end
bot.run
