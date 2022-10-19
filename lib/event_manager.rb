# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(number)
  14018685000
  digits = number.scan(/\d/).join('')
  if digits.length == 11 && digits.start_with?('1')
    digits = digits[1..-1]
  elsif digits.length < 10 || digits.length > 10
    digits = "No Number"
  end
  digits
end


def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  
  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
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

hours_hash = {}
day_hash = {}

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phone_number = clean_phone_number(row[:homephone])

  reg_time = Time.strptime(row[:regdate], "%D %R")
  
  hour = reg_time.hour.to_s
  if hours_hash.has_key?(hour)
    hours_hash[hour] = hours_hash[hour] + 1
  else
    hours_hash[hour] = 1
  end

  day = reg_time.wday
  if day_hash.has_key?(day)
    day_hash[day] = day_hash[day] + 1
  else
    day_hash[day] = 1
  end
 
  # Convert registration date/time into a time object

  # Select the hour info from the time object

  # Create an array or hash that updates for each attendee's registration hour

  # Display the most common hour from the hash/array]


  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

registrations_by_hour = hours_hash.sort_by(&:last)
puts ""
puts "The most common hour for registration is #{registrations_by_hour[-1][0]}, then #{registrations_by_hour[-2][0]}, and #{registrations_by_hour[-3][0]}"

registrations_by_day = day_hash.sort_by(&:last)
puts ""
puts "The most common day of registration is #{registrations_by_day[-1][0]}, then #{registrations_by_day[-2][0]}, and #{registrations_by_day[-3][0]}"
