#!/usr/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'date'
require 'fileutils'

# Path to the CSV file (adjust if needed)
CSV_FILE = 'comp.csv'

# Read the CSV with headers
CSV.foreach(CSV_FILE, headers: true, encoding: 'utf-8') do |row|
  # Skip rows that are not actual races (e.g. year headers)
  next if row['Вид'].nil? || row['Дата'].nil? || row['Название'].nil?

  # Parse and reformat the date (from "DD.MM.YYYY" to "YYYY-MM-DD")
  begin
    date_obj = Date.strptime(row['Дата'].strip, '%d.%m.%Y')
    iso_date = date_obj.strftime('%Y-%m-%d')
  rescue ArgumentError
    # If the date is malformed or empty, skip this row
    next
  end

  # Sanitize the race name for the filename:
  #  - strip leading/trailing spaces
  #  - replace spaces with hyphens
  #  - remove any slash or backslash
  raw_name = row['Название'].strip
  sanitized_name = raw_name
                     .gsub(/[\/\\]/, '')
                     .gsub(/\s+/, '-')

  filename = "./out/results/#{iso_date}-#{sanitized_name}.md"



  File.open(filename, 'w:utf-8') do |f|
    f.puts '---'

    row.headers.each do |header|
      next if header.nil? || header.strip.empty?

      value = row[header]&.strip || ''

      # Если колонка начинается с "м" и значение пустое — пропускаем
      next if header.start_with?('м') && value.empty?

      # Если имя колонки начинается с "м" и далее сразу цифра — переименуем в "Категория"
      if header =~ /\Aм\d/
        # Если в этой колонке есть значение, запишем его под ключом "Категория"
        next if value.empty?

        out_key = 'Категория'
      else
        out_key = header
      end

      # Экранируем кавычки и спецсимволы в значении, чтобы YAML был валидным
      safe_value = value.gsub('"', '\"')
      f.puts %(#{out_key}: "#{safe_value}")
    end

    f.puts '---'
    f.puts

  end
end
