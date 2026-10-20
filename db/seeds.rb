# Events are created here (or in the Rails console). Each event is served at /<slug>.
# A custom page for an event lives at app/views/invitations/templates/_<slug_with_underscores>.html.erb;
# without one, the default design is used.

Event.find_or_create_by!(slug: "garden-party") do |e|
  e.name = "Summer Garden Party"
  e.timezone = "America/New_York"
  e.starts_at = ActiveSupport::TimeZone[e.timezone].parse("#{(Date.current + 3.weeks).next_occurring(:saturday)} 17:00")
  e.location = "The Rosewood Terrace, 12 Orchard Lane"
  e.details = "An evening of good food, live music and better company. Garden attire encouraged."
  e.reminder_message = "Hi %{name}! Can't wait to see you tomorrow at %{event}, %{when}%{where}. 🌿"
end

Event.find_or_create_by!(slug: "book-club") do |e|
  e.name = "September Book Club"
  e.timezone = "America/Los_Angeles"
  e.starts_at = ActiveSupport::TimeZone[e.timezone].parse("#{(Date.current + 10.days)} 19:00")
  e.location = "Maya's place"
  e.details = "We're discussing \"The Overstory\". Bring a snack to share."
end

Event.find_or_create_by!(slug: "eitan") do |e|
  e.name = "Eitan's Birthday Sleepunder"
  e.timezone = "America/Los_Angeles"
  e.starts_at = ActiveSupport::TimeZone[e.timezone].parse("2026-10-10 17:00")
  e.ends_at = ActiveSupport::TimeZone[e.timezone].parse("2026-10-10 22:00")
  e.location = "9328 Kramerwood Pl, Los Angeles, CA 90034"
  e.details = "A sleepover without the sleeping! Come in your PJs for pizza, games and a movie. Maybe bring a sweater, and your favorite stuffed animal."
  e.reminder_message = "Hi %{name}! Eitan's Birthday Sleepunder is tomorrow at %{when}%{where}. PJs on, and maybe bring a sweater! 🌙"
end

Event.find_or_create_by!(slug: "lev") do |e|
  e.name = "Lev's Captain America 6th Birthday"
  e.timezone = "America/Los_Angeles"
  e.starts_at = ActiveSupport::TimeZone[e.timezone].parse("2026-11-15 15:00")
  e.ends_at = ActiveSupport::TimeZone[e.timezone].parse("2026-11-15 17:00")
  e.location = "9328 Kramerwood Pl, Los Angeles, CA 90034"
  e.details = "Avengers, assemble! Lev is turning 6! Come dressed as your favorite superhero for shield training, games, pizza and cake."
  e.reminder_message = "Hi %{name}! Lev's Captain America 6th Birthday is tomorrow, %{when}%{where}. Suit up, hero! 🛡️"
end

puts "Seeded #{Event.count} events: #{Event.pluck(:slug).join(', ')}"
