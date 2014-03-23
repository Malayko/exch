require 'test_helper'

class WireTransferTest < ActiveSupport::TestCase
  test "should be created in pending state" do
    u = Factory(:user)
    add_money(u, 1000, :eur)
    w = Factory(:wire_transfer, :account => u, :bank_account => Factory(:bank_account, :user => u))
    assert w.pending?
  end

  test "should get processed correctly" do
    u = Factory(:user)
    add_money(u, 1000, :eur)
    w = Factory(:wire_transfer, :account => u, :bank_account => Factory(:bank_account, :user => u))
    w.process!
    assert w.processed?
  end
end
