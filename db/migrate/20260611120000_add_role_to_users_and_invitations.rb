class AddRoleToUsersAndInvitations < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, null: false, default: "member"
    add_column :invitations, :role, :string, null: false, default: "member"
  end
end
