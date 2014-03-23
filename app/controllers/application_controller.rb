class ApplicationController < ActionController::Base
  protect_from_forgery

  helper :all

  before_filter :authenticate_user!,
    :move_xml_params,
    :set_locale,
    :set_time_zone,
    :get_announcements,
    :get_stats
  
  def set_time_zone
    if current_user and !current_user.time_zone.blank?
      Time.zone = ActiveSupport::TimeZone[current_user.time_zone]
    end
  end

  # Sets the locale according to the first subdomain or redirects to a localized
  # version of the requested URL
#  def set_locale
#    locale = I18n.default_locale
#    
#    if I18n.available_locales.map(&:to_s).include?(request.subdomains.first)
#      locale = request.subdomains.first
#    end

#    I18n.locale = locale.to_sym
#  end
  
  def set_locale
    cookies[:locale] = { :value => params[:locale], :expires => 10.years.from_now } if params[:locale]
    I18n.locale = cookies[:locale] || I18n.default_locale
  end

  
  # This method is used to work around the fact that there is only
  # one allowed root node in a well formed XML document, we remove
  # the root node so we get to pretend that XML === JSON
  def move_xml_params
    #if request.content_type =~ /xml/
    #  params.merge! params.delete(:api)
    #end
  end

  # Redirects users to their account page after sign-in
  def after_sign_in_path_for(resource)
    session[:user_return_to] or account_path
  end

  def get_announcements
    if params[:action] == 'welcome' || (params[:controller] == "accounts" && params[:action] == "show")
      @announcements = Announcement.active.all
    end
  end
  
  def get_stats
    
    @currencies = Currency.all
    
    currency = "brl"
    
    if Stats.count < 1 || Stats.last.phigh == nil || Stats.last.plow == nil || Stats.last.pwavg == nil || Stats.last.volume == nil
      raise "Please run `rake bitfication:stats`"
    end
    
    @stats = Stats.last
    
    @last_price = Trade.with_currency(currency).count.zero? ? 0 : Trade.with_currency(currency).plottable(currency).last.ppc
    
  end
  
  
end
