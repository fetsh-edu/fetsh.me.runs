# frozen_string_literal: true

module Gnuplot
  # Module: Gnuplot::Config
  # Purpose: Generate a customizable gnuplot script for visualizing weekly distance data.
  # Parameters:
  #   - img_w: Width of the output image
  #   - img_h: Height of the output image
  #   - out_svg: Output SVG filename
  #   - font: Font settings for text (e.g., 'Sans,10')
  #   - xtics: X-axis tick labels
  #   - step: Step size for Y-axis ticks
  #   - avg: Average value line to be plotted
  #   - stats_max: Maximum Y value from the stats (used to set Y range and additional tic)
  #   - axis_color: Color of the axis lines
  #   - axis_width: Width of the axis lines
  #   - grid_color: Color of the grid lines
  #   - grid_width: Width of the grid lines
  #   - line_color: Color of the data line
  #   - line_width: Width of the data line
  #   - fill_opacity: Opacity for the filled area under the line
  #   - avg_line_color: Color of the average line
  #   - avg_line_width: Width of the average line
  #
  # Usage:
  #   params = { ... }
  #   script = GnuplotConfig.generate_script(params)
  #   IO.popen('gnuplot', 'w') { |gp| gp.puts script }
  module Config
    def self.generate_script(params)
      max = params[:stats_max] * 1.15
      <<~GP
        stats 'weekly.dat' using 2 nooutput
        unset title

        set terminal svg size #{params[:img_w]},#{params[:img_h]} enhanced font '#{params[:font]}'
        set output '#{params[:out_svg]}'

        set xdata time
        set timefmt '%Y-%m-%d'
        set format x ''

        unset border
        set border 3 front lc rgb '#{params[:axis_color]}' lw #{params[:axis_width]}

        set tics textcolor rgb '#{params[:axis_color]}'

        set xtics font '#{params[:font]}' offset 0,0.4 nomirror
        set xtics (#{params[:xtics]})

        set yrange [0:#{max}]
        set ytics font '#{params[:font]}' 0,#{params[:step]},#{params[:stats_max]} nomirror
        set ytics add (#{params[:stats_max]})
        set format y '%.0f км'

        set style line 2 lc rgb '#{params[:avg_line_color]}' lw #{params[:avg_line_width]} dt (15,30)

        set grid ytics lt 0 lw #{params[:grid_width]} lc rgb '#{params[:grid_color]}' dt 2
        set grid xtics lt 0 lw #{params[:grid_width]} lc rgb '#{params[:grid_color]}' dt 2

        set style line 1 lc rgb '#{params[:line_color]}' lw #{params[:line_width]} pt 7 ps 1
        set style fill transparent solid #{params[:fill_opacity]} border -1

        set lmargin 6

        plot 'weekly.dat' using 1:2 with filledcurves y1=0 ls 1 title "", \
            '' using 1:2 with linespoints ls 1 title "Км за неделю", \
            '' using 1:(#{params[:avg]}) with lines ls 2 title "Сред. километраж"
      GP
    end
  end
end
