class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items do |t|
      t.references :checkout, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :product_variant, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 10, scale: 2
      t.decimal :total, precision: 10, scale: 2
      t.string :size

      t.timestamps
    end
  end
end