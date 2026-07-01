class CreatePayouts < ActiveRecord::Migration[8.1]
  def change
    create_table :payouts do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :pix_key_type, null: false
      t.string :pix_key, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end
  end
end
