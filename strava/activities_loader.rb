# frozen_string_literal: true

require 'strava-ruby-client'
require 'dotenv'
require 'multi_json'
require 'fileutils'
require_relative 'client'

module Strava
  # Strava::ActivitiesLoader

  # Handles reading cached Strava activities, fetching new entries via the Strava API,
  # merging them while avoiding duplicates, and persisting both the full activities list
  # and a filtered run-time-series JSON file.

  # Usage:
  #   Strava::ActivitiesLoader.load_and_save!
  #   # Reads ACTIVITIES_FILE, fetches new activities after the last cached one,
  #   # updates both ACTIVITIES_FILE and RUN_TS_FILE on disk.

  # Constants:
  #   ACTIVITIES_FILE - path to the JSON file storing all cached activities
  #   RUN_TS_FILE     - path to the JSON file storing only running activities with fields:
  #                     moving_time, distance, start_date_local, name, id
  module ActivitiesLoader
    ACTIVITIES_FILE = ENV.fetch('ACTIVITIES_FILE', 'activities.json')
    RUN_FILE        = ENV.fetch('RUN_TS_FILE', 'runs.json')

    class << self
      # Main entry point: loads cache, fetches updates, merges, and writes files.
      #
      # @return [void]
      def load_and_save!
        cached = load_cached_activities
        log("We have #{cached.size} activities")

        last = wrap_activity(cached.first)
        log("The latest activity from #{last.start_date} is #{last.to_h.slice('moving_time','distance','name')}")

        new_activities = fetch_new_activities(after: last.start_date.to_i)
        log("New activities after #{last.start_date}: #{new_activities.size}")

        merged = merge_activities(new_activities, cached)
        persist_json(ACTIVITIES_FILE, merged)

        runs = filter_runs(merged)
        persist_json(RUN_FILE, runs)
      end

      private

      # Reads and parses the cached activities JSON file.
      # @return [Array<Hash>]
      def load_cached_activities
        MultiJson.load(File.read(ACTIVITIES_FILE))
      end

      # Wraps a raw activity hash in the Strava::Models::Activity class.
      # @param attrs [Hash]
      # @return [Strava::Models::Activity]
      def wrap_activity(attrs)
        Strava::Models::Activity.new(attrs)
      end

      # Fetches activities from Strava after a given Unix timestamp.
      # @param after: [Integer] epoch seconds
      # @return [Array<Hash>]
      def fetch_new_activities(after:)
        Strava.client.athlete_activities(per_page: 200, after: after)
      end

      # Merges new activities into the cached list, preserving order and uniqueness.
      # @param new_acts [Array<Hash>]
      # @param cached  [Array<Hash>]
      # @return [Array<Hash>]
      def merge_activities(new_acts, cached)
        (new_acts.reverse + cached).uniq
      end

      # Filters merged activities for running entries and selects relevant fields.
      # @param activities [Array<Hash>]
      # @return [Array<Hash>]
      def filter_runs(activities)
        activities
          .select { |a| a['sport_type'] == 'Run' }
          .map { |a| a.slice('id', 'name', 'distance', 'moving_time', 'start_date_local') }
      end

      # Persists a Ruby object as pretty-printed JSON to a file.
      # @param path [String]
      # @param data [Object]
      # @return [void]
      def persist_json(path, data)
        File.write(path, MultiJson.dump(data))
        log("Written #{data.size} items to #{path}")
      end

      # Simple logger to STDOUT.
      # @param msg [String]
      # @return [void]
      def log(msg)
        puts msg
      end
    end
  end
end
