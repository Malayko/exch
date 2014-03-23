# validates that user has balance available for - balance operation; prevents negative balance
class UserBalanceValidator < ActiveModel::EachValidator
  def validate_each(record, field, value)
    if record.new_record? and value and (value < 0) and record.account.is_a?(User) and (value.abs > record.account.balance(record.currency))
      record.errors[field] << (I18n.t "errors.greater_than_balance", :balance => record.account.balance(record.currency), :currency => record.currency)
    end
  end
end
