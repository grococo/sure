# The share of an investment account a holder wants a given security to
# represent, e.g. 80% of a PEA in an MSCI World ETF. Account::Allocation
# compares these targets with the current holdings.
class AllocationTarget < ApplicationRecord
  belongs_to :account
  belongs_to :security

  validates :target_percent, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :security_id, uniqueness: { scope: :account_id }
end
