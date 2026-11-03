require "test_helper"

class TradeRepublicAccountTest < ActiveSupport::TestCase
  setup do
    @item = trade_republic_items(:configured_item)
    @item.trade_republic_accounts.destroy_all
  end

  test "siblings stay within the same account pair" do
    default_portfolio = @item.trade_republic_accounts.create!(kind: "portfolio", currency: "EUR", trade_republic_account_id: "SEC-1")
    default_cash = @item.trade_republic_accounts.create!(kind: "cash", currency: "EUR", trade_republic_account_id: "cash:SEC-1")
    pea_portfolio = @item.trade_republic_accounts.create!(kind: "portfolio", product_type: "TAX_WRAPPER", currency: "EUR", trade_republic_account_id: "SEC-PEA")
    pea_cash = @item.trade_republic_accounts.create!(kind: "cash", product_type: "TAX_WRAPPER", currency: "EUR", trade_republic_account_id: "cash:SEC-PEA")

    assert_equal default_cash, default_portfolio.sibling("cash")
    assert_equal pea_cash, pea_portfolio.sibling("cash")
    assert_equal pea_portfolio, pea_cash.sibling("portfolio")
    assert pea_portfolio.tax_wrapper?
    assert_not default_portfolio.tax_wrapper?
  end

  test "a French family's tax wrapper portfolio becomes a PEA investment account" do
    @item.family.update!(country: "FR")
    pea_portfolio = @item.trade_republic_accounts.create!(kind: "portfolio", product_type: "TAX_WRAPPER", currency: "EUR", name: "Trade Republic PEA Portfolio")
    default_portfolio = @item.trade_republic_accounts.create!(kind: "portfolio", currency: "EUR", name: "Trade Republic Portfolio")

    assert_equal "pea", Account.create_from_trade_republic_account(pea_portfolio).accountable.subtype
    assert_equal "brokerage", Account.create_from_trade_republic_account(default_portfolio).accountable.subtype
  end
end
