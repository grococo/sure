require "test_helper"

class SummariesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    sign_in @user
    ensure_tailwind_build
  end

  test "shows net worth, budget, allocations and loans" do
    get summary_url

    assert_response :success
    assert_select "h1", I18n.t("summaries.show.title")
    assert_select "##{ActionView::RecordIdentifier.dom_id(accounts(:investment), :allocation)}"
    assert_select "a[href=?]", account_path(accounts(:loan))
    assert_select "a[href=?]", edit_account_allocation_targets_path(accounts(:investment))
  end

  test "suggests how to split the requested contribution" do
    account = accounts(:investment)
    account.allocation_targets.create!(security: securities(:aapl), target_percent: 100)

    get summary_url(contribution: 250)

    assert_response :success
    assert_select "input[name=contribution][value=?]", "250"
    assert_select "##{ActionView::RecordIdentifier.dom_id(account, :allocation)} dd", text: /250/
  end

  test "falls back to the default contribution for an invalid amount" do
    accounts(:investment).allocation_targets.create!(security: securities(:aapl), target_percent: 100)

    get summary_url(contribution: "abc")

    assert_response :success
    assert_select "input[name=contribution][value=?]", SummariesController::DEFAULT_CONTRIBUTION.to_s
  end
end
