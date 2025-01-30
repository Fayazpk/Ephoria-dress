class ModifyAddressColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :addresses, :country_id
    remove_column :addresses, :state_id
    remove_column :addresses, :city_id

    add_column :addresses, :country_name, :string
    add_column :addresses, :state_name, :string
    add_column :addresses, :city_name, :string
  end
end
