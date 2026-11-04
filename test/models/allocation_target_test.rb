require "test_helper"

class AllocationTargetTest < ActiveSupport::TestCase
  test "keeps the target between 0 and 100 percent" do
    target = AllocationTarget.new(account: accounts(:investment), security: securities(:aapl), target_percent: 120)

    assert_not target.valid?
    assert target.errors.of_kind?(:target_percent, :less_than_or_equal_to)
  end

  test "allows one target per security and account" do
    AllocationTarget.create!(account: accounts(:investment), security: securities(:aapl), target_percent: 50)
    duplicate = AllocationTarget.new(account: accounts(:investment), security: securities(:aapl), target_percent: 10)

    assert_not duplicate.valid?
  end
end
