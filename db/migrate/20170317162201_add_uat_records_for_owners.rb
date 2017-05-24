class AddUatRecordsForOwners < ActiveRecord::Migration
  def up
    ats = execute('SELECT id, user_id FROM atmosphere_appliance_types')
    ats.each do |at|
      if at['user_id'].present?
        execute("
          INSERT INTO atmosphere_user_appliance_types(appliance_type_id, user_id, role)
          VALUES(#{at['id']}, #{at['user_id']}, 'manager')
          ")
      end
    end
  end

  def down
  end
end
