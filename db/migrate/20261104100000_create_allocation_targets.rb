class CreateAllocationTargets < ActiveRecord::Migration[8.1]
  def change
    create_table :allocation_targets, id: :uuid do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: false
      t.references :security, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.decimal :target_percent, precision: 5, scale: 2, null: false

      t.timestamps
    end

    add_index :allocation_targets, %i[account_id security_id], unique: true
    add_check_constraint :allocation_targets, "target_percent >= 0 AND target_percent <= 100", name: "chk_allocation_targets_percent_range"
  end
end
