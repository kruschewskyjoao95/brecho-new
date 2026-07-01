class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.integer :price_cents, null: false
      t.integer :price_promo_cents
      t.string :category, null: false
      t.string :sizes
      t.string :colors
      t.integer :stock, null: false, default: 1
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
