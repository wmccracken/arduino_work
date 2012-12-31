#!/usr/bin/env ruby

require 'rubygems'
require 'serialport'
require 'cosm-rb'
require 'rrd'

SERIAL_SPEED = 19200
SERIAL_PORT = "/dev/ttyAMA0"
COSM_FEED = "90879"
COSM_API_KEY = "Ldz4rPhVPd7iDeGqhzO1zuOLxAeSAKxrYndUUjVUUmFoQT0g"
RRD_PATH = "/users/willwgm3/work/rrds"

# sp = SerialPort.new("/dev/ttyAMA0", "19200".to_i)
# sp.write("This is some more stuff\n")
# sp.write("asdfgh\n")
# sp.close

def main
  # open serial connection
  begin
    @sp = SerialPort.new(SERIAL_PORT, SERIAL_SPEED)
  rescue Exception => e
    puts ("Error opening serial port: #{e.message}")
  end

  send_to_imp("This is a test")

  trap("ALRM") { break_from_loop }
  trap("TERM") { break_from_loop }
  trap("KILL") { break_from_loop }
  @run = true
  while(@run)
    feed = get_cosm_feed
    unless feed.nil?
      datastreams = feed.datastreams
      datastreams.each do |d|
        begin
          rrd_path = "#{RRD_PATH}/#{d.id}.rrd"
          unless File.exists?(rrd_path)
            create_rrd_file(d.id, d.tags)
          end

          rrd = RRD::Base.new(rrd_path)
          puts "Setting value: #{d.id} - #{d.current_value} at #{DateTime.parse(d.updated).to_time.to_i}"
          rrd.update DateTime.parse(d.updated).to_time, d.current_value

          # make a graph

          # Generating a graph with memory and cpu usage from myrrd.rrd file
          RRD.graph "#{d.id}.png", :title => d.tags, :width => 800, :height => 250, :color => ["FONT#000000", "BACK#FFFFFF"] do
            line rrd_path, d.tags => :average, :color => "#00FF00", :label => d.tags
          end
        rescue Exception => e
          puts ("Error processing datastream: #{e.message}")
          puts (e.backtrace)
        end
      end
    end
    sleep 60
  end
end

def create_rrd_file(rrd_name=nil, ds_name=nil)
  if rrd_name && ds_name
    begin
      path = "#{RRD_PATH}/#{rrd_name}.rrd"
      rrd = RRD::Base.new(path)

      puts "Creating rrd file at #{path}"
      rrd.create :start => (DateTime.now - 5).to_time, :step => 5.minutes do
        datasource ds_name, :type => :gauge, :heartbeat => 10.minutes, :min => 0, :max => :unlimited
        archive :average, :every => 5.minutes, :during => 3.months
        archive :average, :every => 30.minutes, :during => 6.months
        archive :average, :every => 1.hour, :during => 1.year
        archive :average, :every => 2.hours, :during => 5.years
      end

      puts "Populating RRD with historica data"
      
      more = true
      next_time = nil
      while more
        ds = get_historic_datapoints(rrd_name, next_time)
        ds.datapoints.each do |dp|
          begin
            rrd.update DateTime.parse(dp.at).to_time, dp.value
          rescue Exception => x
            puts "Error inserting value: #{x.message}"          
          end
        end
        if ds.datapoints.count < 1000
          more = false
        else
          next_time = ds.datapoints.last.at
        end
      end

    rescue Exception => e
      puts "Error creating rrd file: #{e.message}"
    end

  end
end

def get_historic_datapoints(datasource=nil,start_time=nil)
  puts("Updating Historic COSM Feed #{COSM_FEED}..")
  begin
    if start_time.nil?
      opts="?new_datastore=true&duration=5days&interval=300&per_page=1000"
    else
      opts="?new_datastore=true&start=#{start_time}&interval=300&per_page=1000"
    end

    puts "OPTS: #{opts}"
    c = Cosm::Client.get("/v2/feeds/#{COSM_FEED}/datastreams/#{datasource}.json#{opts}", :headers => {"X-ApiKey" => COSM_API_KEY})
    Cosm::Datastream.new(c.body)
  rescue Exception => e
    puts ("Error getting cosm feed: #{e.message}")
    return nil
  end
end

def get_cosm_feed
  puts("Updating COSM Feed #{COSM_FEED}..")
  begin
    c = Cosm::Client.get("/v2/feeds/#{COSM_FEED}.json", :headers => {"X-ApiKey" => COSM_API_KEY})
    Cosm::Feed.new(c.body)
  rescue Exception => e
    puts ("Error getting cosm feed: #{e.message}")
    return nil
  end
end

def break_from_loop
  puts "Program is terminating..."
  @run = false
end

def send_to_imp(message)
  if @sp
    sp.write("#{message}\n")
  else
    puts "WARNING: Cannot send message. Serial port is not opened."
  end
end

# entry point
if __FILE__ == $PROGRAM_NAME
  main()
end
