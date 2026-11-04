require "test_helper"

class AllocationTargetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    @account = accounts(:investment)
    sign_in @user
  end

  test "edit lists the held securities" do
    get edit_account_allocation_targets_url(@account)

    assert_response :success
    assert_select "input[name=?]", "targets[#{securities(:aapl).id}]"
  end

  test "update saves targets and removes cleared ones" do
    @account.allocation_targets.create!(security: securities(:aapl), target_percent: 10)

    patch account_allocation_targets_url(@account), params: { targets: { securities(:aapl).id => "80,5" } }

    assert_redirected_to summary_path
    assert_equal 80.5.to_d, @account.allocation_targets.find_by!(security: securities(:aapl)).target_percent

    patch account_allocation_targets_url(@account), params: { targets: { securities(:aapl).id => "" } }

    assert_empty @account.allocation_targets.reload
  end

  test "update rejects targets above 100 percent" do
    msft = securities(:msft)
    @account.holdings.create!(security: msft, date: Date.current, qty: 1, price: 10, amount: 10, currency: "USD")

    patch account_allocation_targets_url(@account), params: { targets: { securities(:aapl).id => "70", msft.id => "40" } }

    assert_response :unprocessable_entity
    assert_empty @account.allocation_targets.reload
  end

  test "update ignores securities the account neither holds nor targets" do
    stranger = Security.create!(ticker: "NVDA", name: "Nvidia", exchange_operating_mic: "XNAS")

    patch account_allocation_targets_url(@account), params: { targets: { stranger.id => "50" } }

    assert_redirected_to summary_path
    assert_empty @account.allocation_targets.reload
  end

  test "another family's investment account is out of reach" do
    sign_in users(:empty)

    get edit_account_allocation_targets_url(@account)

    assert_response :not_found
  end
end
