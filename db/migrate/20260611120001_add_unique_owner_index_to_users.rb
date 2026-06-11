class AddUniqueOwnerIndexToUsers < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :account_id,
              unique: true,
              where: "role = 'owner'",
              name: "index_users_on_account_id_unique_owner"
  end
end
