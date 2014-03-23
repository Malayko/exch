module TradeOrdersHelper
  def dark_pool_message(count)
    if count.to_i > 1
      t :order_dark_pool_some
    else
      t :order_dark_pool
    end
  end

  def to_delete_link_for(trade_order)
    link_to image_tag("delete.png", :title => t(".delete_order"), :alt => t(".delete_order")),
      account_trade_order_path(trade_order),
      :method => :delete,
      :class => "delete",
      :confirm => t(".delete_order_confirm")
  end

  def activate_link_for(trade_order)
    link_to image_tag("play.png", :title => t(".activate_order"), :alt => t(".activate_order")),
      account_trade_order_activate_path(trade_order),
      :method => :post,
      :class => "activate",
    :confirm => t(".activate_order_confirm")
  end

  def format_amount(amount, currency, precision = 4)
    "#{number_to_currency(amount, :unit => "", :precision => precision)} #{currency + ("&nbsp;" * (5 - currency.size))}".html_safe
  end

  def dark_pool_icon_for(trade_order)
    if trade_order.dark_pool?
      image_tag "dark-pool.png",
        :alt => t(:dark_pool_order),
        :title => t(:dark_pool_order)
    end
  end
  
  def currency_as_options(c, options = {})
    result = ""

    exclusions = options[:exclude] || ''
    exclusions = [exclusions].flatten.map(&:to_s).map(&:upcase)
    
    Currency.where("code NOT IN (#{exclusions.map{ |excluded| "'#{excluded}'" }.join(",")})").all.each do |currency|
      result << content_tag(:option, :value => currency.code, :selected => (c == currency.code)) do
        "#{t("activerecord.extra.currency.codes.#{currency.code.downcase}")} (#{currency.code})"
      end
    end
    
    result.html_safe
  end
end
