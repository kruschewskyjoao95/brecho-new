class AddExtraAdCreditsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :extra_ad_credits, :integer, default: 0, null: false
  end
end
