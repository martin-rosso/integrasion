# Nexo::Element.destroy_all
# Nexo::Folder.destroy_all
# Event.destroy_all

# today = Time.zone.today
# 10.times.each do |i|
#   index = i + 1
#
#   offset = index % 5
#   date = today + offset.days
#
#   event = Event.create(date_from: date, date_to: date, summary: "Test event #{index}")
#   # EventReceiver.new.synchronizable_created(event)
# end


integration = Nexo::Integration.first
folder = Nexo::Folder.kept.first
unless folder.present?
  folder = Nexo::Folder.create!(
    integration:,
    protocol: :calendar,
    name: "Nexo Automated Test",
    description: "Automatically created calendar for Nexo Automated Test"
  )
  Nexo::EventReceiver.new.folder_changed(folder)
end

# folder.elements.kept.each do |el|
#   event = el.synchronizable
#   aux = event.date_from
#   event.date_from = aux - 1.week
#   event.date_to = aux - 1.week
#   event.save
#   EventReceiver.new.synchronizable_updated(event)
# end

# sleep 2
# folder.elements.kept.each do |el|
#   event = el.synchronizable
#   event.update(summary: "Test event 2 #{rand(20..99)}")
#   EventReceiver.new.synchronizable_updated(event)
# end




# folder.discard!
# EventReceiver.new.folder_discarded(folder)
