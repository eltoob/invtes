class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "Invites <invites@ext.scribemd.ai>")
  layout "mailer"
end
