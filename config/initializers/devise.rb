# Use this hook to configure devise mailer, warden hooks and so forth. The first
# four configuration values can also be set straight in your models.
Devise.setup do |config|
  # ==> Mailer Configuration
  # Configure the e-mail address which will be shown in DeviseMailer.
  config.mailer_sender = "Bitfication support <support@bitfication.com>"

  # Configure the class responsible to send e-mails.
  # config.mailer = "Devise::Mailer"

  # ==> ORM configuration
  # Load and configure the ORM. Supports :active_record (default) and
  # :mongoid (bson_ext recommended) by default. Other ORMs may be
  # available as additional gems.
  require 'devise/orm/active_record'

  # ==> Configuration for any authentication mechanism
  # Configure which keys are used when authenticating an user. By default is
  # just :email. You can configure it to use [:username, :subdomain], so for
  # authenticating an user, both parameters are required. Remember that those
  # parameters are used only when authenticating and not when retrieving from
  # session. If you need permissions, you should implement that in a before filter.
  config.authentication_keys = [ :name ]

  # Tell if authentication through request.params is enabled. True by default.
  # config.params_authenticatable = true

  # Tell if authentication through HTTP Basic Auth is enabled. True by default.
  config.http_authenticatable = true

  # Set this to true to use Basic Auth for AJAX requests.  True by default.
  config.http_authenticatable_on_xhr = true

  # The realm used in Http Basic Authentication
  config.http_authentication_realm = "Bitfication"

  # ==> Configuration for :database_authenticatable
  # For bcrypt, this is the cost for hashing the password and defaults to 10. If
  # using other encryptors, it sets how many times you want the password re-encrypted.
  config.stretches = 10

  # Define which will be the encryption algorithm. Devise also supports encryptors
  # from others authentication tools as :clearance_sha1, :authlogic_sha512 (then
  # you should set stretches above to 20 for default behavior) and :restful_authentication_sha1
  # (then you should set stretches to 10, and copy REST_AUTH_SITE_KEY to pepper)
  config.encryptor = :bcrypt

  # Setup a pepper to generate the encrypted password.
  config.pepper = "91ad1e1ce0cabde16074553f385b11635b09fb44495d546e75a025bb9671f2715f4642e21d4dcf5c10e9077d81fb14833f1a8d29a9aaaea831c348d7f9837aa5"

  # ==> Configuration for :confirmable
  # The time you want to give your user to confirm his account. During this time
  # he will be able to access your application without confirming. Default is nil.
  # When confirm_within is zero, the user won't be able to sign in without confirming. 
  # You can use this to let your user access some features of your application 
  # without confirming the account, but blocking it after a certain period 
  # (ie 2 days). 
  # WM changed to false
  config.confirm_within = false

  # ==> Configuration for :rememberable
  # The time the user will be remembered without asking for credentials again.
  # config.remember_for = 2.days

  # If true, a valid remember token can be re-used between multiple browsers.
  # config.remember_across_browsers = true

  # If true, extends the user's remember period when remembered via cookie.
  # config.extend_remember_period = false

  # ==> Configuration for :validatable
  # Range for password length
  config.password_length = 6..100

  # Regex to use to validate the email address
  config.email_regexp = /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i

  # ==> Configuration for :timeoutable
  # The time you want to timeout the user session without activity. After this
  # time the user will be asked for credentials again.
  config.timeout_in = 30.minutes

  # ==> Configuration for :lockable
  # Defines which strategy will be used to lock an account.
  # :failed_attempts = Locks an account after a number of failed attempts to sign in.
  # :none            = No lock strategy. You should handle locking by yourself.
  config.lock_strategy = :failed_attempts

  # Defines which strategy will be used to unlock an account.
  # :email = Sends an unlock link to the user email
  # :time  = Re-enables login after a certain amount of time (see :unlock_in below)
  # :both  = Enables both strategies
  # :none  = No unlock strategy. You should handle unlocking by yourself.
  config.unlock_strategy = :both

  # Number of authentication tries before locking an account if lock_strategy
  # is failed attempts.
  config.maximum_attempts = 3

  # Time interval to unlock the account if :time is enabled as unlock_strategy.
  config.unlock_in = 24.hours
  
    # ==> Configuration for :recoverable
  #
  # Defines which key will be used when recovering the password for an account
  # config.reset_password_keys = [ :email ]

  # Time interval you can reset your password with a reset password key.
  # Don't put a too small interval or your users won't have the time to
  # change their passwords.
  config.reset_password_within = 6.hours

  # ==> Configuration for :encryptable
  # Allow you to use another encryption algorithm besides bcrypt (default). You can use
  # :sha1, :sha512 or encryptors from others authentication tools as :clearance_sha1,
  # :authlogic_sha512 (then you should set stretches above to 20 for default behavior)
  # and :restful_authentication_sha1 (then you should set stretches to 10, and copy
  # REST_AUTH_SITE_KEY to pepper).
  #
  # Require the `devise-encryptable` gem when using anything other than bcrypt
  # config.encryptor = :sha512  
  
  # ==> Configuration for :token_authenticatable
  # Defines name of the authentication token params key
  config.token_authentication_key = :auth_token

  # ==> Scopes configuration
  # Turn scoped views on. Before rendering "sessions/new", it will first check for
  # "users/sessions/new". It's turned off by default because it's slower if you
  # are using only default views.
  # config.scoped_views = true

  # Configure the default scope given to Warden. By default it's the first
  # devise role declared in your routes.
  # config.default_scope = :user

  # Configure sign_out behavior. 
  # By default sign_out is scoped (i.e. /users/sign_out affects only :user scope).
  # In case of sign_out_all_scopes set to true any logout action will sign out all active scopes.
  # config.sign_out_all_scopes = false

  # ==> Navigation configuration
  # Lists the formats that should be treated as navigational. Formats like
  # :html, should redirect to the sign in page when the user does not have
  # access, but formats like :xml or :json, should return 401.
  # If you have any extra navigational formats, like :iphone or :mobile, you
  # should add them to the navigational formats lists. Default is [:html]
  # config.navigational_formats = [:html, :iphone]

  # ==> Warden configuration
  # If you want to use other strategies, that are not (yet) supported by Devise,
  # you can configure them inside the config.warden block. The example below
  # allows you to setup OAuth, using http://github.com/roman/warden_oauth
  #
  # config.warden do |manager|
  #   manager.oauth(:twitter) do |twitter|
  #     twitter.consumer_secret = <YOUR CONSUMER SECRET>
  #     twitter.consumer_key  = <YOUR CONSUMER KEY>
  #     twitter.options :site => 'http://twitter.com'
  #   end
  #   manager.default_strategies(:scope => :user).unshift :twitter_oauth
  # end

  config.paranoid = true

  require 'devise/strategies/ga_otp_authenticatable'
  require 'devise/strategies/yk_otp_authenticatable'

  config.warden do |manager|
    manager.default_strategies(:scope => :user).unshift :ga_otp_authenticatable
    manager.default_strategies(:scope => :user).unshift :yk_otp_authenticatable    
  end
end
