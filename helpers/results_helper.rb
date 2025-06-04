# frozen_string_literal: true

module ResultsHelper
  def distance_icon(distance)
    if distance.start_with?('10')
      "<span class='distance-icon ten'>10</span>"
    elsif distance.start_with?('21')
      "<span class='distance-icon half'>21</span>"
    elsif distance.start_with?('42')
      "<span class='distance-icon marathon'>42</span>"
    else
      "<span class='distance-icon unknown'>#{distance}</span>"
    end
  end

  def format_place_with_percentile(place_str)
    s = place_str.to_s.strip
    percentile_ = percentile(s)
    return s if percentile_.nil?

    "#{place_i} / #{total_i} (#{percentile_}%)"
  end

  def percentile(place)
    s = place.to_s.strip

    parts = s.split(/\s*\/\s*/)
    return nil unless parts.size == 2

    begin
      place_i = Integer(parts[0])
      total_i = Integer(parts[1])
    rescue ArgumentError
      return nil
    end

    return nil if total_i <= 0 || place_i < 1 || place_i > total_i

    ((total_i - place_i) * 100.0 / total_i).round(1).to_s
  end
end
