class CreateJobs < ActiveRecord::Migration[7.2]
  def change
    create_table :jobs do |t|
      t.string :title
      t.string :status
      t.integer :priority
      t.text :data
      t.text :error_message
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
    add_index :jobs, :status
  end
end
