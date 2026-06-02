class CreatePlanFeatures < ActiveRecord::Migration[8.1]
  def change
    create_table :plan_features do |t|
      t.references :plan, null: false, foreign_key: true
      t.references :feature, null: false, foreign_key: true
      t.boolean :enabled, null: false, default: false
      t.integer :limit_value

      t.timestamps
    end

    add_index :plan_features, [ :plan_id, :feature_id ], unique: true
  end
end
