class ApplicationMailer < ActionMailer::Base
  default from: Setting::FROM_EMAIL
  #'valeriiadidushok@gmail.com'
  layout 'mailer'
end
