class CreateCignaforhcpSearches < ActiveRecord::Migration
  def change
    create_table :cignaforhcp_searches do |t|
      t.string  "patient_id"
      t.string  "dob"
      t.string  "first_name"
      t.string  "last_name"

      t.timestamps null: false
    end
  end
end
