class CreateBanners < ActiveRecord::Migration[8.0]
  def change
    create_table :banners do |t|
      t.string :title
      t.string :description
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
