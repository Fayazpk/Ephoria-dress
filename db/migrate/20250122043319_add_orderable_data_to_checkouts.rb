class AddOrderableDataToCheckouts < ActiveRecord::Migration[8.0]
  def change
    add_column :checkouts, :orderable_data, :jsonb, default: {}
  end
end
