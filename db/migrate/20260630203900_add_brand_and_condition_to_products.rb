class AddBrandAndConditionToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :brand, :string
    add_column :products, :condition, :string
  end
end
