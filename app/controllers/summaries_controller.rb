# A short, phone-friendly home: net worth, this month's budget, how each
# investment account compares with its target split, and what is left on
# loans. Each card links to the full page for details.
class SummariesController < ApplicationController
  include BudgetOwnership

  DEFAULT_CONTRIBUTION = 1_000

  def show
    @balance_sheet = Current.family.balance_sheet
    accounts = Current.user.accessible_accounts.visible

    @budget = resolve_budget(Date.current)
    @budget_editable = @budget.editable_by?(Current.user)
    @budget_switch_options = budget_switch_options(@budget)
    @top_budget_categories = @budget.initialized? ? @budget.top_spending_categories : []

    @contribution = contribution_param
    @allocations = accounts.where(accountable_type: "Investment").alphabetically.map(&:allocation)
    @loans = accounts.where(accountable_type: "Loan").alphabetically

    @breadcrumbs = [ [ t("breadcrumbs.home"), root_path ], [ t(".title"), nil ] ]
  end

  private
    def contribution_param
      value = params[:contribution].presence&.to_d
      value&.positive? ? value : DEFAULT_CONTRIBUTION.to_d
    rescue ArgumentError
      DEFAULT_CONTRIBUTION.to_d
    end
end
