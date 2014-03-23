module Admin::TicketsHelper
  def title_column(record, options)
    link_to(record.title, user_ticket_path(record))
  end
end
