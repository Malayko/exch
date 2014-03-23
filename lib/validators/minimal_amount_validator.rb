class MinimalAmountValidator < ActiveModel::EachValidator
  def validate_each(record, field, value)
    if value and (value.abs < Transfer.minimal_amount_for(record.currency, false))
      record.errors[field] << I18n.t("errors.min_amount", :minimum => Transfer.minimal_amount_for(record.currency, true), :currency => record.currency)
    end
  end
end
