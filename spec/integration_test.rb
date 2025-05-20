module Nexo
  def self.create_calendar(folder)
    service = ServiceBuilder.instance.build_protocol_service(folder)
    response = service.insert_calendar(folder)
    folder.update(external_identifier: response.id)
  end

  def self.delete_calendar(folder)
    service = ServiceBuilder.instance.build_protocol_service(folder)
    response = service.remove_calendar(folder)
  end

  # Element.destroy_all
  # Folder.destroy_all
  # Event.destroy_all

  integration = Integration.first
  folder = Folder.first
  unless folder.present?
    folder = Folder.create!(
      integration:,
      protocol: :calendar,
      name: "Nexo Automated Test",
      description: "Automatically created calendar for Nexo Automated Test"
    )
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


  # create_calendar(folder)

  # today = Time.zone.today
  # 10.times.each do |i|
  #   index = i + 1

  #   offset = index % 5
  #   date = today + offset.days

  #   event = Event.create(date_from: date, date_to: date, summary: "Test event #{index}")
  #   # EventReceiver.new.synchronizable_created(event)
  # end


  # EventReceiver.new.synchronizable_created(event)
  # FolderSyncJob.perform_later(folder)

  delete_calendar(folder)

  # Nexo::ServiceBuilder.instance.build_protocol_service( Nexo::Folder.first).remove_calendar(Nexo::Folder.first)
end
