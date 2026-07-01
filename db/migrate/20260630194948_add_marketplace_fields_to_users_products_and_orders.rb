class AddMarketplaceFieldsToUsersProductsAndOrders < ActiveRecord::Migration[8.1]
  def change
    # Users fields (address for sellers)
    add_column :users, :cep, :string
    add_column :users, :address_street, :string
    add_column :users, :address_number, :string
    add_column :users, :address_complement, :string
    add_column :users, :address_neighborhood, :string
    add_column :users, :address_city, :string
    add_column :users, :address_state, :string

    # Products reference to user (seller)
    add_reference :products, :user, foreign_key: true, null: true

    # Orders reference to seller
    add_reference :orders, :seller, foreign_key: { to_table: :users }, null: true
    add_column :orders, :tracking_code, :string
    add_column :orders, :shipping_status, :string, default: "pending_shipment"
  end
end
