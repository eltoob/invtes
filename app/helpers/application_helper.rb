module ApplicationHelper
  # "5 PM" on the hour, "5:30 PM" otherwise.
  def short_time(time)
    time.strftime(time.min.zero? ? "%-l %p" : "%-l:%M %p")
  end
end
