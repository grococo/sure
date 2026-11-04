require "test_helper"

class Account::AllocationTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(
      family: families(:dylan_family),
      name: "PEA",
      balance: 1_000,
      currency: "USD",
      accountable: Investment.new
    )
    @aapl = securities(:aapl)
    @msft = securities(:msft)
    hold(@aapl, 900)
    hold(@msft, 100)
  end

  test "compares holdings with their target share" do
    @account.allocation_targets.create!(security: @aapl, target_percent: 80)
    @account.allocation_targets.create!(security: @msft, target_percent: 20)

    allocation = @account.allocation
    aapl, msft = allocation.lines

    assert_equal Money.new(1_000, "USD"), allocation.total
    assert_equal @aapl, aapl.security
    assert_equal 90.to_d, aapl.actual_percent
    assert_equal(-10.to_d, aapl.gap_percent)
    assert_equal 10.to_d, msft.actual_percent
    assert_equal 10.to_d, msft.gap_percent
  end

  test "lists a targeted security the account does not hold yet" do
    nvda = Security.create!(ticker: "NVDA", name: "Nvidia", exchange_operating_mic: "XNAS")
    @account.allocation_targets.create!(security: nvda, target_percent: 10)

    line = @account.allocation.lines.find { |l| l.security == nvda }

    assert_equal Money.new(0, "USD"), line.value
    assert_equal 0.to_d, line.actual_percent
    assert_equal 10.to_d, line.target_percent
  end

  test "spreads a contribution over the underweight securities first" do
    @account.allocation_targets.create!(security: @aapl, target_percent: 80)
    @account.allocation_targets.create!(security: @msft, target_percent: 20)

    # After 100 more, 20% of 1,100 is 220: MSFT is 120 short, so all of it goes there.
    assert_equal({ @aapl => Money.new(0, "USD"), @msft => Money.new(100, "USD") }, @account.allocation.contribution_split(100))

    # After 1,000 more, the targets are 1,600 and 400: shortfalls 700 and 300 cover it exactly.
    assert_equal({ @aapl => Money.new(700, "USD"), @msft => Money.new(300, "USD") }, @account.allocation.contribution_split(1_000))

    # Past the shortfalls, the remainder follows the targets.
    assert_equal({ @aapl => Money.new(1_500, "USD"), @msft => Money.new(500, "USD") }, @account.allocation.contribution_split(2_000))
  end

  test "suggests nothing without targets" do
    assert_not @account.allocation.targets?
    assert_equal({}, @account.allocation.contribution_split(1_000))
  end

  private
    def hold(security, amount)
      @account.holdings.create!(security: security, date: Date.current, qty: 1, price: amount, amount: amount, currency: "USD")
    end
end
