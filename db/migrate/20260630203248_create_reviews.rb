class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :order, null: false, foreign_key: true, index: { unique: true }
      t.references :buyer, null: true, foreign_key: { to_table: :users }
      t.references :seller, null: false, foreign_key: { to_table: :users }
      t.integer :rating, null: false
      t.text :comment

      t.timestamps
    end
  end
end
