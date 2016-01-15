require 'rubygems'
require 'json'
require 'oauth'

class Tweet 
  attr_accessor :date_time, :screen_name, :message

  def initialize(date_time, screen_name, message)
    @date_time = date_time
    @screen_name = screen_name
    @message = message
  end

  def pretty_meta_data 
    puts "************** Tweet: **************"
    puts @message
    puts "By: #{@screen_name}"
    puts "On: #{@date_time}"
    puts "\n"
  end
end

class TweetFetcher
  attr_accessor :consumer_key, :consumer_secret, :access_token, :access_token_secret
 
  def initialize(auth)
    @consumer_key = auth[:consumer_key]
    @consumer_secret = auth[:consumer_secret]
    @access_token = auth[:access_token]
    @access_token_secret = auth[:access_token_secret]
  end

  def consumer
    OAuth::Consumer.new(consumer_key, consumer_secret, site:'https://api.twitter.com/')
  end

  def endpoint 
    #TODO validate consumer/token
    OAuth::AccessToken.new(consumer, access_token, access_token_secret)
  end

  def fetch
    puts "Please enter phrase you want to search"
    phrase_value = gets.chomp;
    request_uri = "https://api.twitter.com/1.1/search/tweets.json?q=#{phrase_value}";
    response = endpoint.get("#{request_uri}")
    parse_tweets(JSON.parse(response.body))
  end

  def parse_tweets(result)
    tweets = []
    unless result["statuses"].nil?
      result["statuses"].each do |tweet_hash|
        tweets << Tweet.new(tweet_hash['created_at'], tweet_hash['user']['screen_name'], tweet_hash['text']) 
      end
    else
      puts "Sorry! No results found"
    end

    return tweets
  end
 
end

tweet_fetcher = TweetFetcher.new({consumer_key: '***', consumer_secret: '***', access_token: '***', access_token_secret:'***'})

tweets = tweet_fetcher.fetch

tweets.each do |tweet|
  puts tweet.pretty_meta_data 
end
