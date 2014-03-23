require 'test_helper'

class TradeOrderTest < ActiveSupport::TestCase
  test "should market order ppc should be null" do
    market_order = Factory(:market_order,
      :user => Factory(:user),
      :amount => 100,
      :currency => "EUR",
      :category => "buy"
    )

    assert_nil market_order.ppc
  end

  test "should correctly perform a simple trade order" do
    trader1 = Factory(:user)
    trader2 = Factory(:user)

    add_money(trader1, 35.0, :lrusd)
    add_money(trader2, 100.0, :btc)

    buy_order = Factory(:limit_order,
      :amount => 100.0,
      :category => "buy",
      :currency => "LRUSD",
      :ppc => 0.27,
      :user => trader1
    )

    sell_order = Factory(:limit_order,
      :amount => 100.0,
      :category => "sell",
      :currency => "LRUSD",
      :ppc => 0.25,
      :user => trader2
    )

    assert buy_order.active?, "Order should be active"
    assert sell_order.active?, "Order should be active"

    assert_difference 'Trade.count' do
      buy_order.execute!
    end

    assert_equal trader1.balance(:btc),   BigDecimal("100.0")
    assert_equal trader1.balance(:lrusd), BigDecimal("10.0")
    assert_equal trader2.balance(:btc),   BigDecimal("0.0")
    assert_equal trader2.balance(:lrusd), BigDecimal("25.0")

    assert_destroyed sell_order
    assert_destroyed buy_order
  end

  test "should correctly perform a trade order with a limiting order" do
    trader1 = Factory(:user)
    trader2 = Factory(:user)

    add_money(trader1, 25.0, :lrusd)
    add_money(trader2, 100.0, :btc)

    buy_order = Factory.build(:limit_order,
      :user => trader1,
      :amount => 1000.0,
      :category => "buy",
      :currency => "LRUSD",
      :ppc => 0.27
    )

    sell_order = Factory.build(:limit_order,
      :user => trader2,
      :amount => 100.0,
      :category => "sell",
      :currency => "LRUSD",
      :ppc => 0.25
    )

    # We force validation skipping in order to record a trade order for a user
    # that does not have a sufficient balance for it to be fully executed
    buy_order.save(:validate => false)
    sell_order.save(:validate => false)

    assert_difference 'Trade.count' do
      buy_order.execute!
    end

    assert_equal trader1.balance(:btc),   BigDecimal("100.0")
    assert_equal trader1.balance(:lrusd), BigDecimal("0.0")
    assert_equal trader2.balance(:btc),   BigDecimal("0.0")
    assert_equal trader2.balance(:lrusd), BigDecimal("25.0")

    assert_destroyed sell_order
    assert_not_destroyed buy_order

    assert !buy_order.reload.active?,
      "Purchase should not be active anymore, for the buyer has insufficient balance"

    assert_equal buy_order.reload.amount, BigDecimal("900.0")
  end

  test "should correctly perform a trade order with a limiting balance" do
    trader1 = Factory(:user)
    trader2 = Factory(:user)

    add_money(trader1, 100.0, :lrusd)
    add_money(trader2, 10000.0, :btc)

    assert_equal trader2.balance(:btc), BigDecimal("10000.0")
    assert_equal trader1.balance(:lrusd), BigDecimal("100.0")

    buy_order = Factory.build(:limit_order,
      :user => trader1,
      :amount => 1000.0,
      :category => "buy",
      :currency => "LRUSD",
      :ppc => 0.27
    )

    sell_order = Factory.build(:limit_order,
      :user => trader2,
      :amount => 1000.0,
      :category => "sell",
      :currency => "LRUSD",
      :ppc => 0.25
    )

    # Orders are invalid, we save them anyway because we want to make sure trade
    # amounts will be limited by accounts balances
    buy_order.save(:validate => false)
    sell_order.save(:validate => false)

    assert_difference 'Trade.count' do
      buy_order.execute!
    end

    assert_equal trader1.balance(:btc), BigDecimal("400.0")
    assert_equal trader1.balance(:lrusd), BigDecimal("0.0")
    assert_equal trader2.balance(:btc), BigDecimal("9600.0")
    assert_equal trader2.balance(:lrusd), BigDecimal("100.0")

    assert sell_order.reload.active?
    assert !buy_order.reload.active?
    assert_equal buy_order.reload.amount, BigDecimal("600.0")
  end

  test "asks should get matched in ppc descending order and get traded at ask price when a bid is executed" do
    # Before, ask VS bid would always get matched at bid price even when a newly created
    # bid was executing againt outstanding asks. For example with 3 asks at 15, 13, and 10, a bid
    # with a 0.5 ppc would execute against the 15 ask at 0.5 until the 15 ask got completed which
    # allowed for bogus price moves and non-intuitive behaviour
    trader1 = Factory(:user)
    trader2 = Factory(:user)

    add_money(trader1, 100.0, :btc)
    add_money(trader2, 10000.0, :lrusd)

    assert_equal 100.0, trader1.balance(:btc)
    assert_equal 10000.0, trader2.balance(:lrusd)
    assert_equal 0.0, trader1.balance(:lrusd)
    assert_equal 0.0, trader2.balance(:btc)

    bid_at_8 = Factory(:limit_order,
      :user => trader1,
      :amount => 100.0,
      :category => "sell",
      :currency => "LRUSD",
      :ppc => 8.0
    )

    ask_at_14 = Factory(:limit_order,
      :user => trader2,
      :amount => 75.0,
      :category => "buy",
      :currency => "LRUSD",
      :ppc => 14.0
    )

    ask_at_12 = Factory(:limit_order,
      :user => trader2,
      :amount => 75.0,
      :category => "buy",
      :currency => "LRUSD",
      :ppc => 12.0
    )

    ask_at_10 = Factory(:limit_order,
      :user => trader2,
      :amount => 75.0,
      :category => "buy",
      :currency => "LRUSD",
      :ppc => 10.0
    )

    # Check matched orders, and their correct sorting
    assert_equal [ask_at_14, ask_at_12, ask_at_10].map(&:id), bid_at_8.matching_orders.map(&:id)

    assert_difference 'TradeOrder.count', -2 do
      assert_difference 'Trade.count', 2 do
        assert_difference 'AccountOperation.count', 12 do
          bid_at_8.execute!
        end
      end
    end

    assert_equal 0.0, trader1.balance(:btc)
    assert_equal 8650.0, trader2.balance(:lrusd)
    assert_equal 1350.0, trader1.balance(:lrusd)
    assert_equal 100.0, trader2.balance(:btc)
  end

  test "should correctly perform a trade order with 5 decimal places rounding" do
    trader1 = Factory(:user)
    trader2 = Factory(:user)

    add_money(trader1, 25.0, :lrusd)
    add_money(trader2, 100.0, :btc)

    buy_order = Factory.build(:limit_order,
      :user => trader1,
      :amount => 100.0,
      :category => "buy",
      :currency => "LRUSD",
      :ppc => 0.271
    )

    sell_order = Factory.build(:limit_order,
      :user => trader2,
      :amount => 1000.0,
      :category => "sell",
      :currency => "LRUSD",
      :ppc => 0.2519
    )

    # Orders are invalid, we save them anyway because we want to make sure trade
    # amounts will be limited by accounts balances and correctly rounded
    buy_order.save(:validate => false)
    sell_order.save(:validate => false)

    assert_difference 'Trade.count' do
      buy_order.execute!
    end

    assert_equal trader1.balance(:btc), 99.24573
    assert_equal trader1.balance(:lrusd), 0.0
    assert_equal trader2.balance(:btc), 0.75427
    assert_equal trader2.balance(:lrusd), 25.0

    assert !sell_order.reload.active?
    assert !buy_order .reload.active?
    assert_equal buy_order.amount, 0.75427
  end

  test "should correctly handle trade activation when insufficient balance" do
    trader1 = Factory(:user)
    trader2 = Factory(:user)

    add_money(trader1, 25.0, :lrusd)
    add_money(trader2, 100.0, :btc)

    assert_equal 25.0, trader1.balance(:lrusd)

    t = Factory.build(:limit_order,
      :category => "buy",
      :amount => 1.0,
      :ppc => 25.0,
      :user => trader1,
      :currency => "LRUSD"
    )

    assert t.valid?, "Trade order should be valid at this point"

    t.ppc = 25.1
    assert !t.valid?, "Trade order shouldn't be valid anymore"

    t.ppc = 25.0
    assert t.valid?, "Trade should be valid again, yay!"

    assert t.save, "Saving should be smooth"

    assert_no_difference "t.amount" do
      assert_no_difference "Trade.count" do
        t.execute!
      end
    end

    t.ppc = 25.1
    assert t.valid?, "Trade order should remain valid since it's an update"
    assert t.save, "Saving should be smooth, so should shaving be"

    # Now, if we try to create a matching order, that could fill completely the first one
    # and try to execute it against the first one we should end up with an unactivated order
    # with 0.1 remaining amount.

    t2 = LimitOrder.new do |to|
      to.category = "sell"
      to.amount = 50
      to.ppc = 25.0
      to.user = trader2
      to.currency = "LRUSD"
    end

    assert t2.save, "Order should be valid and get properly saved"

    assert_equal BigDecimal("25.0"), trader1.balance(:lrusd)
    assert_equal BigDecimal("100.0"), trader2.balance(:btc)

    assert t.matching_orders.include?(t2), "Orders should be matched"
    assert t2.matching_orders.map(&:id).include?(t.id), "Orders should be matched"

    assert_difference "TradeOrder.count", -1 do
      assert_difference "Trade.count" do
        assert_difference "AccountOperation.count", 6 do
          t.execute!
        end
      end
    end

    assert trader1.balance(:lrusd).zero?
    assert_equal BigDecimal("1.0"), trader1.balance(:btc)
    assert_equal BigDecimal("99.0"), trader2.balance(:btc)
    assert_equal BigDecimal("25.0"), trader2.balance(:lrusd)
    assert_equal BigDecimal("49.0"), t2.reload.amount

    assert_destroyed t, "Buying trade order should be destroyed"
    assert_not_destroyed t2, "Buying trade order should be destroyed"
    assert t2.reload.active?, "Selling trade order should be active"
  end

  test "should correctly handle trade activation when insufficient balance with execution triggered from other order" do
    trader1 = Factory(:user)
    trader2 = Factory(:user)

    add_money(trader1, 25.0, :lrusd)
    add_money(trader2, 100.0, :btc)

    assert_equal 25.0, trader1.balance(:lrusd)

    t = Factory.build(:limit_order,
      :category => "buy",
      :amount => 1.0,
      :ppc => 25.0,
      :user => trader1,
      :currency => "LRUSD"
    )

    assert t.valid?, "Trade order should be valid at this point"

    t.ppc = 25.1
    assert !t.valid?, "Trade order shouldn't be valid anymore"

    t.ppc = 25.0
    assert t.valid?, "Trade should be valid again, yay!"

    assert t.save, "Saving should be smooth"

    assert_no_difference "t.amount" do
      assert_no_difference "Trade.count" do
        t.execute!
      end
    end

    t.ppc = 25.1
    assert t.valid?, "Trade order should remain valid since it's an update"
    assert t.save, "Saving should be smooth, so should shaving be"

    # Now, if we try to create a matching order, that could fill completely the first one
    # and try to execute it against the first one we should end up with an unactivated order
    # with 0.1 remaining amount.

    t2 = LimitOrder.new do |to|
      to.category = "sell"
      to.amount = 50
      to.ppc = 25.0
      to.user = trader2
      to.currency = "LRUSD"
    end

    assert t2.save, "Order should be valid and get properly saved"

    assert_equal 25.0, trader1.balance(:lrusd)
    assert_equal 100.0, trader2.balance(:btc)

    assert t.matching_orders.include?(t2), "Orders should be matched"
    assert t2.matching_orders.include?(t), "Orders should be matched"

    assert_no_difference "TradeOrder.count" do
      assert_difference "Trade.count" do
        assert_difference "AccountOperation.count", 6 do
          t2.execute!
        end
      end
    end

    assert trader1.balance(:lrusd).zero?
    assert_equal 0.99602.to_d, trader1.balance(:btc)
    assert_equal 99.00398.to_d, trader2.balance(:btc)
    assert_equal 25.0.to_d, trader2.balance(:lrusd)
    assert_equal 49.00398.to_d, t2.reload.amount
    assert_equal 0.00398.to_d, t.reload.amount

    assert_not_destroyed t, "Buying trade order should be destroyed"
    assert_not_destroyed t2, "Buying trade order should be destroyed"
    assert t2.reload.active?, "Selling trade order should be active"
    assert !t.reload.active?, "Buying trade order should not be active"
  end

  test "should auto inactivate on funds withdrawal" do
    trader1 = Factory(:user)

    add_money(trader1, 25.0, :lrusd)

    t = Factory.build(:limit_order,
      :category => "buy",
      :amount => 1.0,
      :ppc => 25.0,
      :user => trader1,
      :currency => "LRUSD"
    )

    assert t.save, "Order is valid, should be saved smoothly"
    assert t.reload.active?, "Order should be active"

    add_money(trader1, -5.0, :lrusd)

    assert_equal BigDecimal("20.0"), trader1.balance(:lrusd)
    assert !t.reload.active?, "Order should have been auto-inactivated"
  end

  test "should not inactivate orders that have just enough funds and get partially filled" do
    trader1 = Factory(:user)
    trader2 = Factory(:user)

    add_money(trader1, 25.0, :lrusd)
    add_money(trader2, 100.0, :btc)

    assert_equal 25.0, trader1.balance(:lrusd)
    assert_equal 100.0, trader2.balance(:btc)

    t = Factory.build(:limit_order,
      :category => "buy",
      :amount => 200,
      :ppc => 0.125,
      :user => trader1,
      :currency => "LRUSD"
    )

    assert t.save, "Order should get saved"

    t2 = Factory.build(:limit_order,
      :category => "sell",
      :amount => 100,
      :ppc => 0.125,
      :user => trader2,
      :currency => "LRUSD"
    )

    assert t2.save, "Order should get saved"

    t.execute!

    assert t.reload.active?, "Order should remain active"
    assert_equal 100.0, t.amount
    assert_destroyed t2, "Order should have been destroyed since it got filled completely"
  end

  test "should be able to re-activate order" do
    trader1 = Factory(:user)
    trader2 = Factory(:user)

    add_money(trader1, 25.0, :lrusd)

    assert_equal 25.0, trader1.balance(:lrusd)

    t = nil

    assert_no_difference "Transfer.count" do
      t = Factory(:limit_order,
        :category => "buy",
        :amount => 1.0,
        :ppc => 25.0,
        :user => trader1,
        :currency => "LRUSD"
      )
    end

    assert t.active?

    assert_raise RuntimeError do
      # Activating an already active order
      t.activate!
    end

    add_money(trader1, -20, :lrusd)

    assert !t.reload.active?, "Order should get inactivated by transfer"

    assert_raise RuntimeError do
      t.activate!
    end

    add_money(trader1, 40, :lrusd)

    assert !t.reload.active?, "Order should *not* get activated by transfer"

    assert_nothing_raised do
      t.activate!
    end
  end

  test "order activation should trigger execution" do
    trader1 = Factory(:user)
    trader2 = Factory(:user)

    add_money(trader1, 25.0, :lrusd)
    add_money(trader2, 100.0, :btc)

    assert_equal 25.0, trader1.balance(:lrusd)

    t = nil

    assert_no_difference "Transfer.count" do
      t = Factory(:limit_order,
        :category => "buy",
        :amount => 1.0,
        :ppc => 25.0,
        :user => trader1,
        :currency => "LRUSD"
      )
    end

    assert t.active?

    add_money(trader1, -20.0, :lrusd)

    assert !t.reload.active?, "Order should get inactivated by transfer"

    assert_no_difference "AccountOperation.count" do
      Factory(:limit_order,
        :category => "sell",
        :amount => 1.0,
        :ppc => 20.0,
        :user => trader2,
        :currency => "LRUSD"
      )
    end

    add_money(trader1, 20, :lrusd)

    assert_difference "AccountOperation.count", 6 do
      t.activate!
      assert t.active?
    end
  end

  test "execution should use ppc order and not created_at" do
    trader1 = Factory(:user)
    trader2 = Factory(:user)

    add_money(trader1, 5000.0, :btc)
    add_money(trader2, 1000000.0, :lrusd)

    assert_equal BigDecimal("1000000.0"), trader2.balance(:lrusd)

    Factory(:limit_order,
      :category => "sell",
      :amount   => 1000,
      :ppc      => 3.4,
      :user     => trader1,
      :currency => "LRUSD",
      :created_at => 10.seconds.ago
    )

    Factory(:limit_order,
      :category => "sell",
      :amount   => 1000,
      :ppc      => 3.3,
      :user     => trader1,
      :currency => "LRUSD",
      :created_at => 11.seconds.ago
    )

    Factory(:limit_order,
      :category => "sell",
      :amount   => 1000,
      :ppc      => 3.5,
      :user     => trader1,
      :currency => "LRUSD",
      :created_at => 12.seconds.ago
    )

    Factory(:limit_order,
      :category => "sell",
      :amount   => 1000,
      :ppc      => 3.2,
      :user     => trader1,
      :currency => "LRUSD",
      :created_at => 13.seconds.ago
    )

    Factory(:limit_order,
      :category => "sell",
      :amount   => 1000,
      :ppc      => 3.0,
      :user     => trader1,
      :currency => "LRUSD",
      :created_at => 14.seconds.ago
    )

    t = Factory(:limit_order,
      :category => "buy",
      :amount   => 250,
      :ppc      => 4.0,
      :user     => trader2,
      :currency => "LRUSD"
    )

    t.execute!

    assert_equal BigDecimal("999250.0"), trader2.balance(:lrusd)
  end

  test "a limit order should execute against a market order" do
    t1 = Factory(:user)
    t2 = Factory(:user)

    add_money(t1, BigDecimal("1000.0"), :btc)
    add_money(t2, BigDecimal("1000.0"), :eur)

    market = Factory(:market_order,
      :category => "buy",
      :amount   => 250,
      :user     => t2,
      :currency => "EUR"
    )

    limit = Factory(:limit_order,
      :category => "sell",
      :amount   => 250,
      :ppc      => 0.1,
      :user     => t1,
      :currency => "EUR"
    )

    assert limit.matching_orders.include?(market)

    limit.execute!

    assert_equal BigDecimal("975.0"), t2.balance(:eur)
    assert_equal BigDecimal("250.0"), t2.balance(:btc)
  end


  test "a market order should execute against a limit order" do
    t1 = Factory(:user)
    t2 = Factory(:user)

    add_money(t1, BigDecimal("1000.0"), :btc)
    add_money(t2, BigDecimal("1000.0"), :eur)

    market = Factory(:market_order,
      :category => "buy",
      :amount   => 250,
      :user     => t2,
      :currency => "EUR"
    )

    limit = Factory(:limit_order,
      :category => "sell",
      :amount   => 250,
      :ppc      => 0.1,
      :user     => t1,
      :currency => "EUR"
    )

    assert market.matching_orders.include?(limit)

    market.execute!

    assert_equal BigDecimal("975.0"), t2.balance(:eur)
    assert_equal BigDecimal("250.0"), t2.balance(:btc)
  end

  test "execution should use ppc order only" do
    trader1 = Factory(:user)
    trader2 = Factory(:user)

    add_money(trader1, 5000.0, :btc)
    add_money(trader2, 1000000.0, :lrusd)

    assert_equal BigDecimal("1000000.0"), trader2.balance(:lrusd)

    Factory(:limit_order,
      :category => "sell",
      :amount   => 1000,
      :ppc      => 3.4,
      :user     => trader1,
      :currency => "LRUSD",
      :created_at => 10.seconds.ago
    )

    Factory(:limit_order,
      :category => "sell",
      :amount   => 1000,
      :ppc      => 3.3,
      :user     => trader1,
      :currency => "LRUSD",
      :created_at => 11.seconds.ago
    )

    Factory(:limit_order,
      :category => "sell",
      :amount   => 1000,
      :ppc      => 3.5,
      :user     => trader1,
      :currency => "LRUSD",
      :created_at => 12.seconds.ago
    )

    Factory(:limit_order,
      :category => "sell",
      :amount   => 1000,
      :ppc      => 3.2,
      :user     => trader1,
      :currency => "LRUSD",
      :created_at => 13.seconds.ago
    )

    Factory(:limit_order,
      :category => "sell",
      :amount   => 1000,
      :ppc      => 3.0,
      :user     => trader1,
      :currency => "LRUSD",
      :created_at => 14.seconds.ago
    )

    t = Factory(:limit_order,
      :category => "buy",
      :amount   => 250,
      :ppc      => 4.0,
      :user     => trader2,
      :currency => "LRUSD"
    )

    t.execute!
    assert_equal BigDecimal("999250.0"), trader2.balance(:lrusd), "Delta #{trader2.balance(:lrusd) - BigDecimal("999250.0")}"
  end

  test "a market order should remain active" do
    t1 = Factory(:user)

    add_money(t1, 1000.0, :btc)

    market = Factory(:market_order,
      :category => "sell",
      :amount   => 250,
      :user     => t1,
      :currency => "EUR"
    )

    limit = Factory(:limit_order,
      :category => "sell",
      :amount   => 250,
      :ppc      => 0.1,
      :user     => t1,
      :currency => "EUR"
    )

    assert market.active?
    assert limit.active?

    add_money(t1, -1000.0, :btc)

    assert !limit.reload.active?
    assert market.reload.active?
  end

  test "a market order should be executed when trader gets money" do
    t1 = Factory(:user)
    t2 = Factory(:user)

    add_money(t2, BigDecimal("1000.0"), :lrusd)

    market = Factory(:market_order,
      :category => "sell",
      :amount   => 250,
      :user     => t1,
      :currency => "LRUSD"
    )

    limit = Factory(:limit_order,
      :category => "buy",
      :amount   => 250,
      :ppc      => 0.1,
      :user     => t2,
      :currency => "LRUSD"
    )


    add_money(t1, BigDecimal("1000.0"), :btc)

    assert_equal BigDecimal("250.0"), t2.balance(:btc)

  end
  
  test "market order should have blank ppc since it won't honor it" do
    mo = Factory.build(:market_order,
      :category => "buy",
      :amount => 1,
      :currency => "EUR",
      :user => Factory(:user)
    )

    assert mo.valid?

    mo.ppc = 1
    assert !mo.valid?
  end

  test "market order should only execute when the user has money" do
    u1 = Factory(:user)
    u2 = Factory(:user)

    add_money(u2, 1000, :btc)

    Factory(:limit_order,
      :category => "sell",
      :user => u2,
      :currency => "EUR",
      :amount => 1000,
      :ppc => 1
    )

    assert_no_difference 'Trade.count' do
      mo = Factory(:market_order,
        :category => "buy",
        :amount => 100,
        :user => u1,
        :currency => "EUR"
      )

      mo.execute!
    end
  end
  
  test "a limit order should not work without money" do
    t1 = Factory(:user)
    t2 = Factory(:user)

    add_money(t1, BigDecimal("1000.0"), :btc)
    add_money(t2, BigDecimal("2000.0"), :eur)

    Factory(:limit_order,
      :category => "sell",
      :amount   => 1000,
      :ppc      => 1.0,
      :user     => t1,
      :currency => "EUR"
    )

    Factory(:limit_order,
      :category => "sell",
      :amount   => 1000,
      :ppc      => 1.0,
      :user     => t1,
      :currency => "EUR"
    )

    t = Factory(:market_order,
      :category => "buy",
      :amount   => 2000,
      :user     => t2,
      :currency => "EUR"
    )

    t.execute!

    assert_equal t1.balance(:btc), BigDecimal("0.0")
  end
  
  test "a fee should be taken" do
    t1 = Factory(:user,
      :commission_rate => BigDecimal("0.1"))
    
    t2 = Factory(:user,
      :commission_rate => BigDecimal("0.2"))

    add_money(t1, 1000, :btc)
    add_money(t2, 1000, :eur)

    Factory(:limit_order,
      :user => t1,
      :category => "sell",
      :amount => 1000,
      :ppc => 1,
      :currency => "EUR"
    )

    t = Factory(:market_order,
      :category => "buy",
      :amount => 1000,
      :currency => "EUR",
      :user => t2
    )

    t.execute!
    
    assert_equal t1.balance(:eur), BigDecimal("900")
    assert_equal Account.storage_account_for(:fees).balance(:eur), 100
    assert_equal Account.storage_account_for(:fees).balance(:btc), 200
  end
  
  test "should not be able to create a very small market order" do
    u = Factory(:user)
    
    mo = Factory.build(:market_order,
      :user => u,
      :currency => 'EUR',
      :category => 'buy',
      :amount => 0.001
    )
   
    assert !mo.valid?
  end
end
