class ApplicationMailer < ActionMailer::Base
  include Rails.application.routes.url_helpers

  default from: "from@example.com"
  layout "mailer"
end
