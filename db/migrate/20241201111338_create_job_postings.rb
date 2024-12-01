class CreateJobPostings < ActiveRecord::Migration[8.0]
  def change
    create_table :job_postings do |t|
      t.string :title, null: false
      t.string :location, null: false
      t.string :company, null: false
      t.text :description, null: false
      t.string :source_url, null: false
      t.string :source_platform
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :job_postings, :source_url, unique: true
    add_index :job_postings, :title
    add_index :job_postings, :location
    add_index :job_postings, :created_at
  end
end
