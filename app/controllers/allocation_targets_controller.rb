# Lets the holder of an investment account set the share each security
# should represent (e.g. 80/10/10). Blank fields remove the target.
class AllocationTargetsController < ApplicationController
  include AccountAuthorizable

  before_action :set_account

  def edit
    @allocation = @account.allocation
  end

  def update
    targets = target_params
    total = targets.values.compact.sum(0.to_d)

    if total > 100
      @allocation = @account.allocation
      @error = t(".over_100", total: total.round(2).to_s("F"))
      return render :edit, status: :unprocessable_entity
    end

    AllocationTarget.transaction do
      @account.allocation_targets.where.not(security_id: targets.compact.keys).destroy_all
      targets.compact.each do |security_id, percent|
        @account.allocation_targets.find_or_initialize_by(security_id: security_id).update!(target_percent: percent)
      end
    end

    redirect_to summary_path, notice: t(".updated")
  end

  private
    def set_account
      @account = Current.user.accessible_accounts.where(accountable_type: "Investment").find(params[:account_id])
      require_account_permission!(@account)
    end

    # { security_id => BigDecimal or nil }, limited to securities the
    # account holds or already targets so a crafted id cannot slip in.
    def target_params
      allowed_ids = (@account.allocation.lines.map { |line| line.security.id }).map(&:to_s)
      raw = params.fetch(:targets, {}).permit(allowed_ids)

      raw.to_h.to_h do |security_id, value|
        percent = value.to_s.tr(",", ".").strip
        [ security_id, percent.empty? ? nil : percent.to_d.clamp(0, 100) ]
      end
    end
end
