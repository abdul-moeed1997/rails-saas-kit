class AddAccountToUsers < ActiveRecord::Migration[8.1]
  def up
    add_reference :users, :account, foreign_key: true

    if User.exists?
      account = Account.create!(name: "Default", subdomain: "default-#{Time.current.to_i}")
      User.update_all(account_id: account.id)
    end

    change_column_null :users, :account_id, false
  end

  def down
    remove_reference :users, :account, foreign_key: true
  end
end
