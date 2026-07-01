class AddMissingIndices < ActiveRecord::Migration[8.0]
  def change
    add_index :products, :category, if_not_exists: true
    add_index :products, :active, if_not_exists: true
    add_index :orders, :seller_id, if_not_exists: true
    add_index :orders, :status, if_not_exists: true
    add_index :carts, :session_token, if_not_exists: true
    add_index :cart_items, [:cart_id, :product_id], if_not_exists: true
  end
end
