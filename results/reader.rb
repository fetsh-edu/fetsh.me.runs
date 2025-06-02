# frozen_string_literal: true
require 'yaml'
require 'date'

# Parses every “*.md” file in folder_path, filters to Вид="бег", groups by year,
module Reader
  # Parses every “*.md” file in folder_path, filters to Вид="бег", groups by year,
  #
  # @param folder_path [String] path to the directory containing Markdown files
  # @return [String] HTML snippet (flex‐columns + embedded CSS/JS)
  def self.read(folder_path)
    group_by_year(
      load_all_entries(folder_path)
        .select { |e| e[:data]['Вид'].to_s.strip.downcase == 'бег' }
    )
  end

  # Loads and parses all Markdown files in the given folder.
  # @return [Array<Hash>] each hash contains:
  #   • :id        – basename of MD file (without ".md")
  #   • :data      – parsed frontmatter hash (keys are Russian strings)
  #   • :date      – Date parsed from data['Дата'], or nil on parse error
  #   • :year      – Integer year from :date (or nil)
  #   • :filename  – full path to the MD file
  def self.load_all_entries(folder_path)
    Dir.glob(File.join(folder_path, '*.md')).map do |path|
      text = File.read(path)
      fm = extract_frontmatter(text)
      data = YAML.safe_load(fm) || {}
      # Strip surrounding quotes if present
      data.transform_values! do |v|
        v.is_a?(String) ? v.strip.sub(/\A["']/, '').sub(/["']\z/, '') : v
      end

      date = Date.parse(data['Дата']) rescue nil

      {
        id:       File.basename(path, '.md'),
        data:     data,
        date:     date,
        year:     date ? date.year : nil,
        filename: path
      }
    end
  end

  # Extracts the YAML frontmatter block between the first two '---' lines.
  # @param text [String] entire file contents
  # @return [String] YAML block without the surrounding '---'
  def self.extract_frontmatter(text)
    if text =~ /\A---\s*(.*?)\s*---/m
      Regexp.last_match(1)
    else
      ''
    end
  end

  # Groups entries by year, discarding any without a valid year.
  # @param entries [Array<Hash>]
  # @return [Hash{Integer => Array<Hash>}] year → [entry hashes]
  def self.group_by_year(entries)
    by_year = entries.select { |e| e[:year] }.group_by { |e| e[:year] }
    # Sort each year’s entries by date ascending
    by_year.each_value { |arr| arr.sort_by! { |e| e[:date] } }
    by_year
  end
end
