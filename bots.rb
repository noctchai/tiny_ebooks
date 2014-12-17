#!/usr/bin/env ruby

require 'twitter_ebooks'
require 'dotenv'  
Dotenv.load(".env")

# This is an example bot definition with event handlers commented out
# You can define as many of these as you like; they will run simultaneously

Ebooks::Bot.new("tiny_ebooks") do |bot|
  # Consumer details come from registering an app at https://dev.twitter.com/
  # OAuth details can be fetched with https://github.com/marcel/twurl
  bot.consumer_key = ENV['EBOOKS_CONSUMER_KEY']# Your app consumer key
  bot.consumer_secret = ENV['EBOOKS_CONSUMER_SECRET'] # Your app consumer secret
  bot.oauth_token = ENV['EBOOKS_OAUTH_TOKEN'] # Token connecting the app to this account
  bot.oauth_token_secret = ENV['EBOOKS_OAUTH_TOKEN_SECRET'] # Secret connecting the app to this account

ROBOT_ID = "ebooks" # Prefer not to talk to other robots
TWITTER_USERNAME = "tiny_ebooks" # Ebooks account username
TEXT_MODEL_NAME = "tiny_ebooks" # This should be the name of the text model

DELAY = 2..30 # Simulated human reply delay range, in seconds
BLACKLIST = ['tinysubversions', 'dril'] # users to avoid interaction with
SPECIAL_WORDS = ['singularity', 'world domination', 'gender' , 'memes'] # Words we like
BANNED_WORDS = ['voldemort', 'evgeny morozov', 'heroku'] # Words we don't want to use

# Track who we've randomly interacted with globally
$have_talked = {}
$banned_words = BANNED_WORDS

# Overwrite the Model#valid_tweet? method to check for banned words
class Ebooks::Model
  def valid_tweet?(tokens, limit)
    tweet = NLP.reconstruct(tokens)
    found_banned = $banned_words.any? do |word|
      re = Regexp.new("\\b#{word}\\b", "i")
      re.match tweet
    end
    tweet.length <= limit && !NLP.unmatched_enclosers?(tweet) && !found_banned
  end
end

class GenBot
  def initialize(bot, modelname)
    @bot = bot
    @model = nil

    bot.consumer_key = CONSUMER_KEY
    bot.consumer_secret = CONSUMER_SECRET

    bot.on_startup do
      @model = Model.load("model/#{modelname}.model")
      @top100 = @model.keywords.top(100).map(&:to_s).map(&:downcase)
      @top50 = @model.keywords.top(20).map(&:to_s).map(&:downcase)
    end

    bot.on_message do |dm|
      bot.delay DELAY do
        bot.reply dm, @model.make_response(dm[:text])
      end
    end

    bot.on_follow do |user|
      bot.delay DELAY do
        bot.follow user[:screen_name]
      end
    end

    bot.on_mention do |tweet, meta|
      # Avoid infinite reply chains
      next if tweet[:user][:screen_name].include?(ROBOT_ID) && rand > 0.05

      author = tweet[:user][:screen_name]
      next if $have_talked.fetch(author, 0) >= 5
      $have_talked[author] = $have_talked.fetch(author, 0) + 1

      tokens = NLP.tokenize(tweet[:text])
      very_interesting = tokens.find_all { |t| @top50.include?(t.downcase) }.length > 2
      special = tokens.find { |t| SPECIAL_WORDS.include?(t) }

      if very_interesting || special
        favorite(tweet)
      end

      reply(tweet, meta)
    end