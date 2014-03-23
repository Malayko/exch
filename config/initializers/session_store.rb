BitcoinBank::Application.config.session_store ActionDispatch::Session::CacheStore, :expire_after => 30.minutes,
  :key => "bc-session",
  :domain => :all
