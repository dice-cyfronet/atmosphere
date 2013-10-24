unless Air.config.exception_notification.blank?
  Air::Application.config.action_mailer.delivery_method = :sendmail
  Air::Application.config.action_mailer.perform_deliveries = true
  Air::Application.config.action_mailer.raise_delivery_errors = true
  Air::Application.config.action_mailer.default_url_options = { host: Air.config.mailer.host }

  Air::Application.config.middleware.use ExceptionNotification::Rack,
    email: {
      email_prefix: Air.config.exception_notification.email_prefix,
      sender_address: Air.config.exception_notification.sender_address,
      exception_recipients: Air.config.exception_notification.exception_recipients
    }
end