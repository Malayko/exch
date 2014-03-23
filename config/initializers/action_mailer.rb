module ActionMailerDefaults
  def mail_with_logo(args, &block)
    attachments.inline['bitlogo.png'] = File.read(File.join(Rails.root, "app", "assets", "images", "bitlogo.png"))
    mail_without_logo(args, &block)
  end

  def self.included(base)
    base.class_eval do
      default :from => "Bitfication support <support@bitfication.com>"
      layout 'mailers'
      alias_method_chain :mail, :logo
    end
  end
end

class BitcoinCentralMailer < ActionMailer::Base
  include ActionMailerDefaults
end
