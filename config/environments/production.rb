BitcoinBank::Application.configure do
  config.cache_classes = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = "X-Sendfile"
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.force_ssl = true

  config.cache_store = :dalli_store, 'localhost'
  
  config.action_mailer.delivery_method = :sendmail
  config.action_mailer.default_url_options = {
    :host => "bitfication.com"
  }
  
  config.middleware.use ::ExceptionNotification::Rack,
    :email => {
      :email_prefix => "[BF Exception] ",	 	
      :sender_address => %w{no-reply@bitfication.com},	 
      :exception_recipients => %w{support@bitfication.com}
    }
  
  # Used to broadcast invoices public URLs
  config.base_url = "https://bitfication.com/"
  config.assets.initialize_on_precompile = true
  config.assets.compress = true
  config.assets.compile = false
  config.assets.digest = true
  config.serve_static_assets = false
end
