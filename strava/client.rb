# frozen_string_literal: true

require 'strava-ruby-client'
require 'dotenv'
require 'multi_json'
require 'fileutils'
Dotenv.load

# Strava module provides a configured Strava API client.
# It handles OAuth token refreshing and persists new refresh tokens to the .env file automatically.

# Usage:
#   client = Strava.client
#   # => Strava::Api::Client instance with a valid access token
module Strava
  class Error < StandardError; end

  class << self
    # Returns a memoized Strava API client with a valid access token.
    # Automatically refreshes tokens and updates the .env file if needed.
    #
    # @return [Strava::Api::Client] configured client
    def client
      @client ||= build_client
    end

    private

    # Builds a new Strava API client after fetching OAuth tokens.
    #
    # @return [Strava::Api::Client]
    def build_client
      token_response = fetch_oauth_token
      refresh_token_if_changed(token_response)
      Strava::Api::Client.new(access_token: token_response['access_token'])
    end

    # Fetches a fresh OAuth token using the refresh token.
    #
    # @return [Hash] response from Strava OAuth endpoint
    def fetch_oauth_token
      Strava::OAuth::Client.new(
        client_id: ENV.fetch('STRAVA_CLIENT_ID'),
        client_secret: ENV.fetch('STRAVA_CLIENT_SECRET')
      ).oauth_token(
        refresh_token: ENV.fetch('STRAVA_API_REFRESH_TOKEN'),
        grant_type: 'refresh_token'
      )
    end

    # Checks if the refresh token has changed and updates .env if so.
    #
    # @param response [Hash] OAuth token response
    # @return [void]
    def refresh_token_if_changed(response)
      new_refresh_token     = response['refresh_token']
      current_refresh_token = ENV['STRAVA_API_REFRESH_TOKEN']
      return if new_refresh_token.nil? || new_refresh_token == current_refresh_token

      log_token_update(current_refresh_token, new_refresh_token)
      update_env_file('.env', 'STRAVA_API_REFRESH_TOKEN', new_refresh_token)
    end

    # Logs details about refresh token updates.
    #
    # @param old_token [String] previous refresh token
    # @param new_token [String] newly issued refresh token
    # @return [void]
    def log_token_update(old_token, new_token)
      puts 'The Strava API refresh token has changed, updating .env'
      puts "Old token: #{old_token}"
      puts "New token: #{new_token}"
    end

    # Updates the .env file with the new value for the given key.
    #
    # @param file_path [String] path to the .env file
    # @param key [String] key to update
    # @param new_value [String] new value for the key
    # @return [void]
    def update_env_file(file_path, key, new_value)
      pattern = /^#{Regexp.escape(key)}=.*$/
      content = File.read(file_path)

      updated = if content.match?(pattern)
                  content.gsub(pattern, "#{key}=#{new_value}")
                else
                  content.chomp + "\n#{key}=#{new_value}\n"
                end
      File.write(file_path, updated)
    end
  end
end
