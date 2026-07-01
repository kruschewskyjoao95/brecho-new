class CreateOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :offers do |t|
      t.references :buyer, null: false, foreign_key: { to_table: :users }
      t.references :product, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end
  end
end
