# frozen_string_literal: true

require 'modulation'

Rubato = import('../../lib/rubato')

def echo(rchan, wchan)
  while msg = rchan.receive
    puts "got #{msg}"
    wchan << "you said: #{msg}"
  end
ensure
  puts "echoer stopped"
end

chan1, chan2 = Rubato::Channel.new, Rubato::Channel.new

echoer = spawn { echo(chan1, chan2) }

spawn do
  chan1 << "hello"
  chan1 << "world"
  
  2.times do
    msg = chan2.receive
    puts msg
  end

  chan1.close
  chan2.close
end
