#!/usr/bin/env ruby

# file: omah.rb
# title: Offline Mail Helper

require 'dynarex-daily'

class Omah

  def initialize(options={})

    opt = {user: ''}.merge options
    @user = opt[:user]

    @dd = DynarexDaily.new 
    @dd.schema = 'messages/message(id, from, to, subject, date, body_text, body_html)'
  end

  def store messages

    dynarex = Dynarex.new 'messages/message(id, title, txt_file, html_file)'

    messages.each do |msg| 

      #puts 'msg[:subject] : ' + msg.subject.inspect
      subject = msg[:subject]
      title = subject.gsub(/\W+/,'-')[0,30].sub(/-$/,'')
      a = dynarex.find_all_by_title subject
      ordinal = a.any? ? '.' + a.length.to_s : ''
      txt_file = title + ordinal + '.txt'
      html_file = title + ordinal + '.html'

      id = msg[:id]
      next if dynarex.find_by_id id

      dynarex.create id: id, title: subject, txt_file: txt_file, 
                  html_file: html_file
      @dd.create msg
      path = File.join @user + '/inbox' 
      FileUtils.mkdir_p path
      File.write File.join(path, txt_file), msg[:body_text]
      File.write File.join(path, html_file), msg[:body_html]
    end

    dynarex.save 'dynarex.xml'
    @dd.save
  end

end