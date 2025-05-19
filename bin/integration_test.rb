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

  integration = Integration.first
  Element.destroy_all
  Folder.destroy_all
  folder = Folder.create!(
    integration:,
    protocol: :dummy_calendar,
    name: "Nexo Automated Test",
    description: "Automatically created calendar for Nexo Automated Test"
  )

  create_calendar(folder)

  today = Time.zone.today
  3.times.each do |index|
    event = Event.create(date_from: today, date_to: today, summary: "Test event #{index}")
    EventReceiver.new.synchronizable_created(event)
  end

  # sleep 3
  delete_calendar(folder)
end
