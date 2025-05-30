# frozen_string_literal: true

require 'date'

class Date
  def monday = self - ((wday + 6) % 7)
  def sunday = monday + 6

  def calendar_week_index
    f_end = first_week_end
    if self <= f_end
      1
    else
      2 + ((self - (f_end + 1)).to_i / 7)
    end
  end

  def year_week_key
    "#{year}-#{calendar_week_index.to_s.rjust(2, '0')}"
  end

  private

  def first_week_end
    jan1   = Date.new(year, 1, 1)
    offset = (7 - jan1.wday) % 7
    jan1 + offset
  end
end
