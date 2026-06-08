class CreateStripeWebhookEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :stripe_webhook_events do |t|
      t.string :stripe_event_id, null: false
      t.string :event_type, null: false
      t.string :status, null: false, default: "processed"
      t.datetime :processed_at
      t.text :error_message

      t.timestamps
    end

    add_index :stripe_webhook_events, :stripe_event_id, unique: true
  end
end
