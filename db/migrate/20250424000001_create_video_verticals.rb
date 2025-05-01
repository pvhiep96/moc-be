class CreateVideoVerticals < ActiveRecord::Migration[7.2]
  def change
    create_table :video_verticals do |t|
      t.references :project, null: false, foreign_key: true, index: { unique: true }
      t.string :url

      t.timestamps
    end
  end
end