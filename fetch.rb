require 'bundler/inline'
require './secrets.rb'

gemfile do
  source 'https://rubygems.org'
  gem 'pco_api', require: 'pco_api'
  gem 'plist', require: 'plist'
  gem 'mail', require: 'mail'
end



api = PCO::API.new(
  basic_auth_token: ENV['token'],
  basic_auth_secret: ENV['secret']
)



puts "Fetching service…"

schedules = api.services.v2.people[ENV['userid']].schedules.get(order: 'starts_at')
num_services = schedules['meta']['count']

if num_services > 0
  service = schedules['data'].first
  date = service['attributes']['short_dates']
  service_type = service['relationships']['service_type']['data']['id']
  plan_id = service['relationships']['plan']['data']['id']

  puts "Fetching songs…"

  items = api.services.v2.service_types[service_type].plans[plan_id].items.get(include: 'arrangement')
  arrangements = items['included']
  set_items = items['data']

  puts ""
  puts "Setlist for #{date}"
  puts "-----------------------"



  # Create the songs array

  body = ''
  songs = []

  METERS = {
    '4/4' => {
      'beatStates' => [1, 1, 1, 1],
      'meterCode' => 4,
      'numBeats' => 4
      },
    '3/4' => {
      'beatStates' => [1, 1, 1],
      'meterCode' => 3,
      'numBeats' => 3
      },
    '6/8' => {
      'beatStates' => [1, 2, 2, 1, 2, 2],
      'meterCode' => 15,
      'numBeats' => 6
    },
    '6/4' => {
      'beatStates' => [1, 1, 1, 1, 1, 1],
      'meterCode' => 6,
      'numBeats' => 6
    },
    # Sometimes the meter isn't set in Services :(
    nil => {
      'beatStates' => [1, 1, 1, 1],
      'meterCode' => 4,
      'numBeats' => 4
    }
  }

  arrangements.each do |arrangement|
    if arrangement['attributes']['bpm']
      arrangement_id = arrangement['id']

      set_items.each do |item|
        item_data = item['relationships']['arrangement']['data']
        item_id = item_data && item_data['id']

        if item_id == arrangement_id
          title = item['attributes']['title']
          bpm = arrangement['attributes']['bpm'].round()
          meter = arrangement['attributes']['meter']

          puts line = "#{title}, #{bpm}, #{meter} \n"

          body << line

          songs.push({
            'MutedBars' => 0,
            'UnmutedBars' => 1,
            'autoStepBPM' => 2,
            'autoStepBars' => 10,
            'autoStepTime' => 30,
            'automatorState' => 0,
            'barTotal' => 100,
            'beatCode' => 0,
            'beatStates' => METERS[meter]['beatStates'],
            'countInBars' => 0,
            'meterCode' => METERS[meter]['meterCode'],
            'numBeats' => METERS[meter]['numBeats'],
            'numSubBeats' => 1,
            'resetAtCountEnd' => false,
            'stopAtCountEnd' => false,
            'subBeatStates' => [1],
            'tempo' => bpm,
            'timerMax' => 300,
            'title' => title,
            'trackerHasMax' => false,
            'trackerState' => 0
            })
        end
      end
    end
  end



  # Create the plist file

  plist = {
    'autoAdvance' => false,
    'loop' => false,
    'songs' => songs,
    'title' => date
  }

  file = File.new("#{date}.slist", 'w')
  file.write(plist.to_plist)
  file.close



  # Mail the setlist to me

  Mail.defaults do
    delivery_method :smtp, { :address    => 'smtp.gmail.com',
                             :port       => 587,
                             :user_name  => ENV['username'],
                             :password   => ENV['password'],
                             :authentication => :plain,
                             :enable_starttls_auto => true
                          }
  end

  mail = Mail.new do
    from     ENV['username']
    to       ENV['username']
    subject  "Setlist for #{date}"
    body     body
    add_file "#{date}.slist"
  end

  mail.deliver

  puts ""
  puts "Setlist emailed!"



  # Clean up the created plist file
  File.delete("#{date}.slist") if File.exist?("#{date}.slist")
else
  puts "There are no services!"
end
