module T65Coin
  module Util
    def self.valid_T65Coin_address?(address)
      # We don't want leading/trailing spaces to pollute addresses
      (address == address.strip) and T65Coin::Client.instance.validate_address(address)['isvalid']
    end

    def self.my_T65Coin_address?(address)
      T65Coin::Client.instance.validate_address(address)['ismine']
    end

    def self.get_account(address)
      T65Coin::Client.instance.get_account(address)
    end
  end
end