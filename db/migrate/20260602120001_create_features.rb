class CreateFeatures < ActiveRecord::Migration[8.1]
  def change
    create_table :features do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    add_index :features, :key, unique: true
  end
end
