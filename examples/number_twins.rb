require 'fa'

numbers = Fa["[0-9]+"]

# Matches numbers that have twin digits somewhere
twins = Fa["[0-9]*(00|11|22|33|44|55|66|77|88|99)[0-9]*"]

# Numbers where adjacent digits are always different
no_twins = numbers.minus(twins)

# Ruby regex from no_twins. We need to mark all '(' as noncapturing groups,
# otherwise Ruby's matcher freaks out
rx = /\A(#{no_twins.to_s.gsub("(", "(?:")})\Z/

["789", "202", "911", "666"].each do |s|
  if s =~ rx
    puts "#{s} has no duplicated digits"
  else
    puts "#{s} has duplicated digits"
  end
end
