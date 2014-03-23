module Admin::PendingTransfersHelper
  def type_column(record, options)
    record.class.to_s.gsub(/Transfer$/, "")
  end
end
