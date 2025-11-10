class CreateInquiries < ActiveRecord::Migration[7.2]
  def change
    create_table :inquiries do |t|
      t.string :full_name
      t.string :email
      t.string :location
      t.string :event_type
      t.string :role
      t.date :event_date
      t.string :event_location
      t.string :budget
      t.string :instagram
      t.string :source
      t.text :message

      t.timestamps
    end
  end
end
