# frozen_string_literal: true

require 'modulation'

Rubato = import('../../lib/rubato')
Postgres =  import('../../lib/rubato/extensions/postgres')

PGOPTS = {
  host:     '/tmp',
  user:     'reality',
  password: nil,
  dbname:   'reality',
  sslmode:  'require'
}

DBPOOL = Rubato::ResourcePool.new(limit: 8) { PG.connect(PGOPTS) }

def get_records(db)
  res = db.query("select pg_sleep(0.0001) as test")
  # puts "got #{res.ntuples} records: #{res.to_a}"
rescue => e
  puts "got error: #{e.inspect}"
  puts e.backtrace.join("\n")
end

CONCURRENCY = ARGV.first ? ARGV.first.to_i : 10
puts "concurrency: #{CONCURRENCY}"

DBPOOL.preheat!
t0 = Time.now
count = 0
coprocs = CONCURRENCY.times.map {
  spawn { loop { DBPOOL.acquire { |db| get_records(db); count += 1 } } }
}
sleep 3
puts "count: #{count} query rate: #{count / (Time.now - t0)} queries/s"
coprocs.each(&:interrupt)