class AddLocationNamesToAddresses < ActiveRecord::Migration[8.0]
  def change
    add_column :addresses, :country_name, :string
    add_column :addresses, :state_name, :string
    add_column :addresses, :city_name, :string

    # Data migration for existing records
    reversible do |dir|
      dir.up do
        Address.find_each do |address|
          address.update_columns(
            country_name: address.country&.name,
            state_name: address.state&.name,
            city_name: address.city&.name
          )
        end
      end
    end
  end
end