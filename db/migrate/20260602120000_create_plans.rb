class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :status, null: false, default: "active"
      t.boolean :highlighted, null: false, default: false
      t.integer :position, null: false, default: 0
      t.string :stripe_product_id

      t.timestamps
    end

    add_index :plans, :slug, unique: true
    add_index :plans, :position
  end
end
