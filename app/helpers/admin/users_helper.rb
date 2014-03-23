module Admin::UsersHelper
  def id_column(record, options)
    record.id.to_s
  end
  
  def name_column(record, options)
    link_to record.name, admin_user_account_operations_path(record)
  end
end
