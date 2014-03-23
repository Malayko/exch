require 'rubygems'
require 'rotp'

totp = ROTP::TOTP.new("ou2clwhjc4gnmzou")
totp.provisioning_uri("BF-U375238") # => 'otpauth://totp/alice@google.com?secret=JBSWY3DPEHPK3PXP'
p "Current OTP: #{totp.now}"
