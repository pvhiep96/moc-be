class AddContentToDescriptions < ActiveRecord::Migration[7.2]
  def change
    add_column :descriptions, :content, :text
  end
end
