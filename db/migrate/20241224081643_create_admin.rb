class CreateAdmin < ActiveRecord::Migration[7.2]
  def change
    create_table :admins do |t|
      t.string :user_name
      t.string :password_digest
      t.string :fullname

      t.timestamps
    end
  end
end
