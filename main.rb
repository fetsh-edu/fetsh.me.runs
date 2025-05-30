#!/usr/bin/env ruby
# frozen_string_literal: true

require 'multi_json'
require 'dotenv'
require_relative 'strava/activities_loader'
require_relative 'calculator/calculator'
require_relative 'gnuplot/svg'
require_relative 'renderer/renderer'

OUT_HTML = ENV.fetch('RUN_HTML', './out/index.html')

# Strava::ActivitiesLoader.load_and_save!
runs = MultiJson.load(File.read(Strava::ActivitiesLoader::RUN_FILE))
stats = Calculator.weekly_stats(runs, 52)
svg = Gnuplot::Svg.generate(
  {
    labels: stats[:labels],
    values: stats[:values],
    img_w: 700,
    img_h: 400,
    left_margin: 42,
    right_margin: 21,
    top_margin: 15,
    bottom_margin: 30,
    out_svg: 'output.svg',
    font: 'Sans,10',
    avg: stats[:average],
    stats_max: stats[:maximum],
    axis_color: '#777777',
    axis_width: 0.5,
    grid_color: '#dddddd',
    grid_width: 1,
    line_color: '#FF8C00',
    line_width: 2,
    fill_opacity: 0.2,
    avg_line_color: '#333333',
    avg_line_width: 0.3
  }
)

heatmap_html = Renderer.render_template(
  :heatmap,
  {
    dates: stats[:dates],
    color_from: [0, 70, 6],
    color_to: [255, 255, 55]
  }
)

weekly_html = Renderer.render_template(
  :weekly,
  {
    svg: svg,
    current_week_km: stats[:current_week_km],
    avg: stats[:average],
    maximum: stats[:maximum],
    max_week_label: stats[:max_week_label]
  }
)
daily_html = Renderer.render_template(
  :daily,
  {
    heatmap_html: heatmap_html,
    map_mode: 'linear'
  }
)

File.write(
  OUT_HTML,
  Renderer.render_template(
    :_layout,
    {
      title: 'Run!',
      css_path: "./css/main.css?v=#{Time.now.strftime('%Y%m%d%H%M%S')}",
      content: weekly_html + daily_html
    }
  )
)
