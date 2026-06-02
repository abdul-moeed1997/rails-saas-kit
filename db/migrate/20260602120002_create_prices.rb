class CreatePrices < ActiveRecord::Migration[8.1]
  def change
    create_table :prices do |t|
      t.references :plan, null: false, foreign_key: true
      t.integer :amount_cents, null: false, default: 0
      t.string :currency, null: false, default: "usd"
      t.string :interval, null: false
      t.string :stripe_price_id
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :prices, [ :plan_id, :interval ], unique: true
  end
end
