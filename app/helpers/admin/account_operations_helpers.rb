module Admin::AccountOperationsHelper
  def user_column(record, options)
    record.user.account
  end
end
