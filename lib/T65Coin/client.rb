module T65Coin
  class Client
    include Singleton
    
    def initialize
      config_file = File.open(File.join(Rails.root, "config", "T65Coin.yml"))
      config = YAML::load(config_file)[Rails.env].symbolize_keys

      @client = JsonWrapper.new(config[:url],
        config[:username],
        config[:password]
      )
    end

    def method_missing(method, *args)
      @client.request({
          :method => method.to_s.gsub(/\_/, ""),
          :params => args
        }
      )
    end
  end
end