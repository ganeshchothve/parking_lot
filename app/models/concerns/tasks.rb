module Tasks
  def map_tasks
    task_hash = tasks.pluck(:key, :name).to_h
    current_client.checklists.each do |checklist|
      if task_hash.keys.include?(checklist.key)
        tasks.find_by(key: checklist.key).set(name: checklist.name) if task_hash[checklist.key] != checklist.name
      else
        tasks << Task.new(name: checklist.name, key: checklist.key, tracked_by: checklist.tracked_by)
      end
    end
  end
end