module ApplicationHelper
  # "5 PM" on the hour, "5:30 PM" otherwise.
  def short_time(time)
    time.strftime(time.min.zero? ? "%-l %p" : "%-l:%M %p")
  end

  # "Saturday, October 10 · 5 PM – 10 PM", in the event's time zone.
  def event_when(event)
    text = "#{event.local_starts_at.strftime("%A, %B %-d")} · #{short_time(event.local_starts_at)}"
    event.local_ends_at ? "#{text} – #{short_time(event.local_ends_at)}" : text
  end
end
