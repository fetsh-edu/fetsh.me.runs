module HeatmapHelper
  def percentage(min, max, x)
    pct = ((x - min).to_f / (max - min)) * 100
    return 100 if pct > 100

    return 0 if pct.negative?

    pct
  end

  def pick_color(c1, c2, t)
    c1.zip(c2).map { |a, b| (a*t + b*(1-t)).round }
  end

  # Градация пробега в текстовый класс
  def distance_to_grade(distance)
    [
      [5_000, "just"],
      [10_000, "ok"],
      [14_000, "good"],
      [18_000, "perfect"],
      [23_000, "long-s"],
      [28_000, "long-m"],
      [41_000, "long-l"]
    ].each { |limit,label| return label if distance < limit }
    "marathon"
  end
end
