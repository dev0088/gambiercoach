class ApplicationMailer < ActionMailer::Base
  default from: Setting::FROM_EMAIL

  layout 'mailer'
end
