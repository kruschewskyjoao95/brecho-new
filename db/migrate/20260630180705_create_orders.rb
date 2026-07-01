class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: true, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.string :shipping_cep
      t.text :shipping_address
      t.integer :shipping_cost_cents, null: false, default: 0
      t.string :shipping_method
      t.string :payment_method
      t.string :payment_id
      t.text :payment_pix_qr_code
      t.text :payment_pix_copia_cola
      t.integer :total_cents, null: false

      t.timestamps
    end
  end
end
