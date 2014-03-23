require 'test_helper'

class LibertyReserveSciTest < ActionDispatch::IntegrationTest
  test "should create a liberty reserve deposit if nicely asked" do
    user = Factory(:user,
      :id => 1959,
      :email => "lr_recipient@domain.tld",
      :password => "password",
      :password_confirmation => "password"
    )

    params = {
      "lr_encrypted2" => "F10A0B287EBD1DDF3471DB1FBA6AE90D7D3B81D7C335E3E51E15B6F6F5360654",
      "lr_amnt" => "30.00",
      "lr_merchant_ref" => "1959",
      "action" => "lr_transfer_success",
      "lr_paidto" => "U4552263",
      "account_id" => "1959",
      "lr_encrypted" => "20EAD57CC98F7069C7420E950D6245EC14201F6ED7142082D5AEE05B92FF9C0B",
      "lr_transfer" => "64203620",
      "controller" => "third_party_callbacks",
      "lr_store" => "Bitfication",
      "lr_fee_amnt" => "0.00",
      "lr_timestamp" => "2011-26-06 18:51:27",
      "lr_currency" => "LRUSD",
      "lr_paidby" => "U6509825"
    }

    assert_difference "user.account_operations.count" do
      post '/third_party_callbacks/lr_create_from_sci', params
      assert_response :success
    end

    # Test that posting a second time doesn't create another transfer
    assert_no_difference "user.account_operations.count" do
      post '/third_party_callbacks/lr_create_from_sci', params
      assert_response :success
    end
  end
end
