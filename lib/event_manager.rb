require 'csv'
require "google-apis-civicinfo_v2"
require 'erb'
require 'time'



def clean_zip(zip)
  zip.to_s.rjust(5, '0')[0..4]
end

def clean_phone(phone)
  phone = phone.to_s.scan(/\d+/).join
  return phone if phone.length == 10
  return phone[1..10] if phone.length == 11 && phone[0] == '1'
  "Invalid Number"
end

def legislators_by_zip (zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    "Find your representative visiting  www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter) 
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def display_accesses_by_day(accesses_by_day_of_week)
  accesses_by_day_of_week.each_with_index do |accesses, index|  
    puts "Day #{Date::DAYNAMES[index]} -> #{accesses} accesses."
  end
end



puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv', 
  headers: true, 
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

accesses_by_hour = Array.new(24, 0)
accesses_by_day_of_week = Array.new(7, 0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  register_date = Time.strptime("#{row[:regdate]}", "%m/%d/%y %k:%M")

  register_hour = register_date.hour

  accesses_by_hour[register_hour] += 1
  
  accesses_by_day_of_week[register_date.wday] += 1
  
  zip = clean_zip(row[:zipcode])
  phone = clean_phone(row[:homephone])

  legislators = legislators_by_zip(zip)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)  

end

display_accesses_by_day(accesses_by_day_of_week)


