# frozen_string_literal: true

require_relative 'config'
require_relative '../date/date'

module Gnuplot
  # Provides a simple interface for generating SVG plots via Gnuplot.
  #
  # This module:
  #   1. Builds a Gnuplot script using GnuplotConfig.
  #   2. Executes Gnuplot to produce an SVG file.
  #   3. Cleans out auto-generated <title> tags for a cleaner SVG output.
  #
  # Usage:
  #   svg_content = Gnuplot::Svg.generate(
  #     out_svg: 'plot.svg',
  #     data: my_data_array,
  #     title: 'My Plot',
  #     xlabel: 'Time',
  #     ylabel: 'Value'
  #   )
  #
  # Parameters:
  #   params [Hash] must include :out_svg (path to write the SVG), plus any other
  #                 keys required by GnuplotConfig.generate_script.
  #
  # Returns:
  #   [String] SVG markup without Gnuplot <title> elements.
  #
  # Raises:
  #   GnuplotError if the Gnuplot executable is missing or the output cannot be read.
  module Svg
    TITLE_PATTERNS = [
      %r{<title>gnuplot_plot_\d+</title>},
      %r{<title>Gnuplot</title>}
    ].freeze

    class << self
      # Generates an SVG via Gnuplot and returns cleaned content.
      #
      # @param params [Hash]
      # @option params [String] :out_svg path for the SVG output
      # @return [String] SVG content without auto-generated titles
      # @raise [GnuplotError] on execution or I/O failures
      def generate(params)
        @params = params
        create_dat
        script = Gnuplot::Config.generate_script(
          params.merge(
            xtics: xtics,
            step: step
          )
        )
        run_gnuplot(script)
        raw_svg = File.read(params.fetch(:out_svg))
        append_labels(clean_svg(raw_svg))
      end

      private

      def params = @params

      def labels = @labels ||= params.fetch(:labels)

      def values = @values ||= params.fetch(:values)

      def max = @max ||= values.max

      def max_padded = max * 1.15

      def step = @step ||= (max / 6.0).ceil

      def weeks = @weeks ||= values.size

      def l_margin = @l_margin ||= params.fetch(:left_margin)
      def r_margin = @r_margin ||= params.fetch(:right_margin)
      def t_margin = @t_margin ||= params.fetch(:top_margin)
      def b_margin = @b_margin ||= params.fetch(:bottom_margin)

      def plot_w = @plot_w ||= params.fetch(:img_w) - l_margin - r_margin
      def plot_h = @plot_h ||= params.fetch(:img_h) - t_margin - b_margin

      def create_dat
        File.write('weekly.dat', labels.zip(values).map { |d, v| "#{d} #{v}" }.join("\n"))
      end

      # Returns a comma-separated string of gnuplot xtics entries,
      # one for each month start between the first and last label dates.
      #
      # @return [String] e.g. "\"янв\" \"2025-01-06\", \"фев\" \"2025-02-03\", …"
      def xtics
        month_starts_between(Date.parse(labels.first), Date.parse(labels.last))
          .map { |d| xtic_entry(d) }
          .join(', ')
      end

      # Russian month abbreviations, indexed 0–11 for Jan–Dec
      MONTH_NAMES = %w[янв фев мар апр май июн июл авг сен окт ноя дек].freeze

      # Build an array of Date objects for the first day of each month
      # from start_date up to end_date.
      #
      # @param start_date [Date]
      # @param end_date   [Date]
      # @return [Array<Date>]
      def month_starts_between(start_date, end_date)
        date = Date.new(start_date.year, start_date.month, 1)
        [].tap do |months|
          while date <= end_date
            months << date
            date = date.next_month
          end
        end
      end

      # Format a single xtic entry for gnuplot:
      #   "<month_label>" "<iso_of_monday>"
      #
      # We take the Monday of the week containing the 1st of the month.
      #
      # @param d [Date] first-of-month date
      # @return [String]
      def xtic_entry(d)
        label    = MONTH_NAMES[d.month - 1]
        position = d.monday.strftime('%Y-%m-%d')
        %("#{label}" "#{position}")
      end

      # Executes Gnuplot with the provided script.
      #
      # @param script [String] Gnuplot commands
      # @return [void]
      # @raise [GnuplotError]
      def run_gnuplot(script)
        IO.popen('gnuplot', 'w') do |gp|
          gp.puts script
          gp.close_write
        end
      rescue Errno::ENOENT => e
        raise GnuplotError, "Gnuplot not found: #{e.message}"
      end

      # Removes unwanted <title> tags from SVG markup.
      #
      # @param svg [String]
      # @return [String]
      def clean_svg(svg)
        TITLE_PATTERNS.reduce(svg) { |content, pattern| content.gsub(pattern, '') }
      end

      def append_labels(svg)
        svg.gsub('</svg>', "#{points_svg}</svg>")
      end

      # Generates a series of SVG <g> points for a line chart.
      #
      def points_svg
        labels.each_with_index.map do |label, i|
          point_svg(px: px(i), py: py(i), title: "#{values[i].round(1)} км (#{label})")
        end.join("\n")
      end

      def px(index)
        (l_margin + plot_w * (index.to_f / (weeks - 1))).round
      end

      def py(index)
        (t_margin + plot_h * (1 - values[index].to_f / max_padded)).round
      end

      # Generates a single SVG <g> point for a line chart.
      #
      # @param px      [Numeric] x-coordinate in px
      # @param py      [Numeric] y-coordinate in px
      # @param title   [String] title for the point
      # @return [String] SVG `<g>` tag
      def point_svg(px:, py:, title:)
        <<~SVG
          <g class="point" transform="translate(#{px},#{py})">
            <circle r="6" class="chart-circle">
              <title>#{title}</title>
            </circle>
            <text y="-20" class="chart-tooltip">#{title}</text>
          </g>
        SVG
      end
    end
  end

  # Custom error raised for Gnuplot-related issues.
  class GnuplotError < StandardError; end
end
