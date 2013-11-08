#!/usr/bin/env ruby

# file: omah.rb
# title: Offline Mail Helper

require 'dynarex-daily'

class Omah

  def initialize()

    @dd = DynarexDaily.new 
    @dd.schema = 'messages/message(id, from, to, subject, date, body_text, body_html)'
  end

  def store messages

    messages.each {|message| dd.create message }
    @dd.save
  end

end
