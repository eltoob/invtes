# Builds "add to calendar" payloads for an event: an .ics file (Apple/Outlook/
# any calendar app) and a Google Calendar link.
class EventCalendar
  DEFAULT_DURATION = 3.hours

  def initialize(event, url: nil)
    @event = event
    @url = url
  end

  def filename = "#{@event.slug}.ics"

  def to_ics
    lines = [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:-//Invites//EN",
      "CALSCALE:GREGORIAN",
      "METHOD:PUBLISH",
      "BEGIN:VEVENT",
      "UID:event-#{@event.id}@invites",
      "DTSTAMP:#{utc(@event.updated_at || Time.current)}",
      "DTSTART:#{utc(starts_at)}",
      "DTEND:#{utc(ends_at)}",
      "SUMMARY:#{escape(@event.name)}",
      ("LOCATION:#{escape(@event.location)}" if @event.location.present?),
      ("DESCRIPTION:#{escape(description)}" if description.present?),
      ("URL:#{@url}" if @url.present?),
      "BEGIN:VALARM",
      "ACTION:DISPLAY",
      "DESCRIPTION:#{escape(@event.name)} is tomorrow",
      "TRIGGER:-P1D",
      "END:VALARM",
      "END:VEVENT",
      "END:VCALENDAR"
    ].compact
    lines.map { |l| fold(l) }.join("\r\n") + "\r\n"
  end

  def google_url
    params = {
      action: "TEMPLATE",
      text: @event.name,
      dates: "#{utc(starts_at)}/#{utc(ends_at)}",
      details: description,
      location: @event.location,
      ctz: @event.timezone
    }.compact_blank
    "https://calendar.google.com/calendar/render?#{params.to_query}"
  end

  private

  def starts_at = @event.starts_at
  def ends_at = @event.ends_at || @event.starts_at + DEFAULT_DURATION

  def description
    [ @event.details, @url ].compact_blank.join("\n\n")
  end

  def utc(time) = time.utc.strftime("%Y%m%dT%H%M%SZ")

  def escape(text)
    text.to_s.gsub("\\", "\\\\\\\\").gsub(";", "\;").gsub(",", "\\,").gsub(/\r?\n/, "\\n")
  end

  # RFC 5545: lines longer than 75 octets are folded with CRLF + space.
  def fold(line)
    return line if line.bytesize <= 75
    out, chunk = [], +""
    line.each_char do |ch|
      if chunk.bytesize + ch.bytesize > (out.empty? ? 75 : 74)
        out << chunk
        chunk = +""
      end
      chunk << ch
    end
    out << chunk
    out.join("\r\n ")
  end
end
