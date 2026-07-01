class AddDefectsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :defects, :text
  end
end
