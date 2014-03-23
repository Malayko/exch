class Manager < User
  def allowed_currencies
    Currency.
      where("id IN (#{used_currencies.where(:management => true).map(&:currency_id).join(",")})").
      map { |c| c.code.downcase.to_sym }
  end
end
