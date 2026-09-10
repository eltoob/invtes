# Invites

Rails 8 + PostgreSQL app for event invitations. Each event gets a smart URL
(`/garden-party`) with a custom RSVP page. Guests RSVP with their name, mobile
number and how many guests they're bringing. They get a confirmation text, and a
reminder text the day before. An admin dashboard lists every response.

## Setup

```bash
bin/setup          # bundle, create dev + queue databases, load seeds
bin/dev            # Puma with Solid Queue embedded (jobs + reminder scheduler)
```

Then open:

- http://localhost:3000/garden-party — custom invitation page (seeded)
- http://localhost:3000/book-club — default invitation design (seeded)
- http://localhost:3000/admin — dashboard, login `admin` / `password` in development

Copy `.env.example` to `.env` (or export the variables) to enable Twilio. Without
credentials, texts are logged instead of sent.

## Creating an event

Events are created in code, not through the UI. Add one to `db/seeds.rb` or in
`bin/rails console`:

```ruby
Event.create!(
  slug: "sarahs-40th",
  name: "Sarah's 40th",
  timezone: "America/New_York",
  starts_at: Time.zone.parse("2026-10-17 19:00"),
  location: "The Loft, Brooklyn",
  reminder_message: "Hi %{name}! Sarah's 40th is tomorrow, %{when}%{where}. 🎉"   # optional
)
```

The reminder is scheduled automatically for 10:00 AM local time the day before
(`reminder_at`, editable). Placeholders available in `reminder_message`:
`%{name}`, `%{event}`, `%{when}`, `%{where}`, `%{date}`, `%{guests}`.

## Custom page per event

Create `app/views/invitations/templates/_<slug_with_underscores>.html.erb`
(for slug `sarahs-40th` → `_sarahs_40th.html.erb`). It receives `event` and
`rsvp`, and can contain any HTML/CSS/JS. Include the shared RSVP form with:

```erb
<%= render "invitations/rsvp_form", event: event, rsvp: rsvp %>
```

Use `content_for :head` for extra `<style>`/`<link>` tags. See
`_garden_party.html.erb` for a complete example and `_default.html.erb` for the
fallback design.

## How reminders work

- `SendEventRemindersJob` runs every 5 minutes (`config/recurring.yml`).
- It picks events whose `reminder_at` has passed and that haven't been reminded,
  then enqueues `SendReminderSmsJob` for each attending guest.
- The admin page also has a "Send reminders now" button.
- Confirmation texts are sent by `SendRsvpConfirmationJob` right after an RSVP.

## Deploying

Set `RAILS_MASTER_KEY`, `DATABASE_URL` (or `INVITES_DATABASE_PASSWORD`), the
Twilio variables and `ADMIN_USERNAME` / `ADMIN_PASSWORD`. Run `bin/jobs` as a
separate process, or set `SOLID_QUEUE_IN_PUMA=1` to run jobs inside Puma.
