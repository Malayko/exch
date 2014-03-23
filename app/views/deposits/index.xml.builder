xml.instruct!

xml.deposits do
  @deposits.each do |deposit|
    xml.deposit :at => deposit.created_at.to_i,
      :currency => deposit.currency,
      :amount => deposit.amount,
      :confirmed => deposit.confirmed?
  end
end