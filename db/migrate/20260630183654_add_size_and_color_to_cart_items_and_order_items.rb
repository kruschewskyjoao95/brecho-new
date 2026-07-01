class AddSizeAndColorToCartItemsAndOrderItems < ActiveRecord::Migration[8.1]
  def change
    add_column :cart_items, :size, :string
    add_column :cart_items, :color, :string
    add_column :order_items, :size, :string
    add_column :order_items, :color, :string
  end
end
