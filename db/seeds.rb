Admin.create! do |user|
  user.password = "2QmaKCs2fhU8x9iS0AAL4F7ACR3aZxNdq6WyTEE1"
  user.password_confirmation = "2QmaKCs2fhU8x9iS0AAL4F7ACR3aZxNdq6WyTEE1"
  user.email = "admin@localhost.local"
  user.skip_captcha = true
  user.confirmed_at = DateTime.now
end

puts "Created \"admin@localhost.local\" user with password \"2QmaKCs2fhU8x9iS0AAL4F7ACR3aZxNdq6WyTEE1\""

Stats.create! do |s|
  s.volume = 0
  s.phigh = 0
  s.plow = 0
  s.pwavg = 0
end
