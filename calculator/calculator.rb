# frozen_string_literal: true

require_relative '../date/date'

# Calculator module for computing weekly running statistics.
#
# Provides a single method `.weekly_stats` that takes an array of run hashes
# and a number of weeks, returning both series data and summary stats.
#
# Example:
#   stats = Calculator.weekly_stats(runs, 8)
#   # {
#   #   labels: [...],
#   #   values: [...],
#   #   current_week_km: 12.3,
#   #   total: 85.6,
#   #   average: 10.7,
#   #   maximum: 15.2,
#   #   max_index: 3,
#   #   max_week_start: #<Date 2025-04-07>,
#   #   max_week_label: "07.04.2025"
#   # }
module Calculator
  # Calculates weekly running stats and series for the past N weeks.
  #
  # @param runs   [Array<Hash>] runs with keys 'start_date_local' and 'distance'
  # @param weeks  [Integer] number of weeks to include (including current)
  # @return [Hash]
  #   :labels            => Array<String> (dates of Mondays 'YYYY-MM-DD')
  #   :values            => Array<Float>  (km per week, rounded)
  #   :current_week_km   => Float        (km in the latest week)
  #   :total             => Float        (sum of values)
  #   :average           => Float        (mean of values)
  #   :maximum           => Float        (highest week km)
  #   :max_index         => Integer      (index of the max week)
  #   :max_week_start    => Date         (start date of max week)
  #   :max_week_label    => String       ("DD.MM.YYYY" of max week)
  def self.weekly_stats(runs, weeks)
    today = Date.today
    start_date = today - 7 * (weeks - 1)

    week_map = build_week_map(runs, start_date, today)
    labels   = build_labels(today.monday, weeks)
    values   = build_values(labels, week_map)
    dates    = build_dates_hierarchy(runs)

    total, avg, max_km, max_idx, max_date, max_label = compute_stats(labels[0...-1], values[0...-1])

    {
      labels:          labels,
      values:          values,
      dates:           dates,
      current_week_km: values.last || 0.0,
      total:           total,
      average:         avg,
      maximum:         max_km,
      max_index:       max_idx,
      max_week_start:  max_date,
      max_week_label:  max_label
    }
  end

  class << self
    private

    def build_week_map(runs, start_date, end_date)
      runs.each_with_object(Hash.new(0.0)) do |r, map|
        dt = DateTime.parse(r['start_date_local']).to_date
        km = r['distance'].to_f / 1000.0
        next unless dt.between?(start_date, end_date)

        map[dt.monday] += km
      end
    end

    def build_labels(week0, weeks)
      (0...weeks).map { |i| (week0 - ((weeks - 1 - i) * 7)).to_s }
    end

    def build_values(labels, week_map)
      labels.map { |d| week_map.fetch(Date.parse(d), 0.0).round(1) }
    end

    def compute_stats(labels, values)
      total   = values.sum
      avg     = total / values.size.to_f
      max_km  = values.max.to_f
      max_idx = values.index(max_km)
      max_date  = Date.parse(labels[max_idx])
      max_label = max_date.strftime('%d.%m.%Y')
      [total, avg, max_km, max_idx, max_date, max_label]
    end

    def build_dates_hierarchy(runs)
      return {} if runs.empty?

      # Determine span across runs
      first_dt = Date.parse(runs.last['start_date_local'])
      last_dt  = Date.parse(runs.first['start_date_local'])
      span_start = Date.new(first_dt.year, 1, 1)
      span_end   = Date.new(last_dt.year, 12, 31)

      # Initialize empty structure
      dates = {}
      (span_start..span_end).each do |d|
        year = d.year
        wk   = d.monday
        dates[year]         ||= {}
        dates[year][wk]     ||= {}
        dates[year][wk][d.iso8601] ||= []
      end

      # Populate with runs
      runs.each do |r|
        d    = DateTime.parse(r['start_date_local']).to_date
        year = d.year
        wk   = d.monday
        iso  = d.iso8601
        dates[year][wk][iso] << r
      end

      dates
    end
  end
end
