unless Air.config.exception_notification.blank?
  Air::Application.config.middleware.use ExceptionNotification::Rack,
    :email => {
      :email_prefix => Air.config.exception_notification.email_prefix,
      :sender_address => Air.config.exception_notification.sender_address,
      :exception_recipients => Air.config.exception_notification.exception_recipients
    }
end