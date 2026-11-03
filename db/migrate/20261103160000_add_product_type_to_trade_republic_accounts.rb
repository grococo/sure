class AddProductTypeToTradeRepublicAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :trade_republic_accounts, :product_type, :string, null: false, default: "DEFAULT"

    remove_index :trade_republic_accounts, [ :trade_republic_item_id, :kind ],
      unique: true, name: "idx_on_trade_republic_item_id_kind_3b60cc72fb"
    add_index :trade_republic_accounts, [ :trade_republic_item_id, :product_type, :kind ],
      unique: true, name: "index_trade_republic_accounts_on_item_product_type_and_kind"
  end
end
