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
end
