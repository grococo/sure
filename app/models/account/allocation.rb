# Compares an investment account's current holdings with the target split
# its holder set (see AllocationTarget), e.g. 80% world / 10% emerging /
# 10% Europe in a PEA, and suggests how to spread the next contribution so
# the account drifts back toward that split without selling anything.
class Account::Allocation
  Line = Data.define(:security, :value, :actual_percent, :target_percent) do
    def name
      security.name.presence || security.ticker
    end

    # Positive when the security sits below its target share.
    def gap_percent
      return nil if target_percent.nil?

      target_percent - actual_percent
    end
  end

  attr_reader :account

  def initialize(account)
    @account = account
  end

  def currency
    account.currency
  end

  def total
    Money.new(holding_values.values.sum(0.to_d), currency)
  end

  def targets?
    targets.any?
  end

  def targets_total_percent
    targets.values.sum(0.to_d)
  end

  # Securities with a holding or a target, largest holding first.
  def lines
    @lines ||= begin
      securities = (holding_values.keys + targets.keys).uniq
      securities.map do |security|
        value = holding_values.fetch(security, 0.to_d)
        Line.new(
          security: security,
          value: Money.new(value, currency),
          actual_percent: total.amount.zero? ? 0.to_d : (value / total.amount * 100).round(1),
          target_percent: targets[security]
        )
      end.sort_by { |line| [ -line.value.amount, line.name.to_s ] }
    end
  end

  # How to spread `amount` over the targeted securities: fill the
  # underweight ones first, in proportion to how far below target they
  # would be once the money lands, then share any remainder by target.
  #
  # @return [Hash{Security => Money}] empty when no target is set
  def contribution_split(amount)
    amount = amount.to_d
    return {} unless amount.positive? && targets_total_percent.positive?

    total_after = total.amount + amount
    shortfalls = targets.to_h do |security, percent|
      wanted = total_after * percent / targets_total_percent
      [ security, [ wanted - holding_values.fetch(security, 0.to_d), 0.to_d ].max ]
    end
    shortfall_total = shortfalls.values.sum(0.to_d)

    targets.to_h do |security, percent|
      share = if shortfall_total >= amount
        amount * shortfalls[security] / shortfall_total
      else
        shortfalls[security] + (amount - shortfall_total) * percent / targets_total_percent
      end
      [ security, Money.new(share.round(2), currency) ]
    end
  end

  private
    def holdings
      @holdings ||= account.current_holdings.includes(:security).to_a
    end

    def holding_values
      @holding_values ||= holdings.each_with_object(Hash.new(0.to_d)) do |holding, values|
        values[holding.security] += value_in_account_currency(holding)
      end
    end

    def targets
      @targets ||= account.allocation_targets.includes(:security).to_h do |target|
        [ target.security, target.target_percent.to_d ]
      end
    end

    def value_in_account_currency(holding)
      return holding.amount.to_d if holding.currency == currency

      holding.amount_money.exchange_to(currency, date: holding.date).amount
    rescue Money::ConversionError
      holding.amount.to_d
    end
end
