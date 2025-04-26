class CreateVideoUrls < ActiveRecord::Migration[7.2]
  def change
    create_table :video_urls do |t|
      t.references :project, null: false, foreign_key: true
      t.string :url

      t.timestamps
    end
  end
end
