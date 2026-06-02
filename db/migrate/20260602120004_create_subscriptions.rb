class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.references :price, null: false, foreign_key: true
      t.string :status, null: false, default: "active"
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :trial_ends_at
      t.boolean :cancel_at_period_end, null: false, default: false
      t.datetime :canceled_at

      t.timestamps
    end

    add_index :subscriptions, :stripe_subscription_id, unique: true, where: "stripe_subscription_id IS NOT NULL"
  end
end
