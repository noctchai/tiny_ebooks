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

  bot.on_message do |dm|
    # Reply to a DM
    # bot.reply(dm, "secret secrets")
  end

  bot.on_follow do |user|
    # Follow a user back
    # bot.follow(user[:screen_name])
  end

  bot.on_mention do |tweet, meta|
    # Reply to a mention
    # bot.reply(tweet, meta[:reply_prefix] + "oh hullo")
  end

  bot.on_timeline do |tweet, meta|
    # Reply to a tweet in the bot's timeline
    # bot.reply(tweet, meta[:reply_prefix] + "nice meme")
  end

  bot.scheduler.every '2h' do
    # Tweet something every 24 hours
    # See https://github.com/jmettraux/rufus-scheduler
    # bot.tweet("hi")
  end
end
