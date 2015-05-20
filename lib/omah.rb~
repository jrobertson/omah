#!/usr/bin/env ruby

# file: omah.rb
# title: Offline Mail Helper

require 'dynarex-daily'

class Omah

  def initialize(options={})

    opt = {user: 'user'}.merge options
    @user = opt[:user]
    FileUtils.mkdir_p @user # attempt to mkdir regardless if it already exists
    Dir.chdir @user
    
    dailyfile = 'dynarexdaily.xml'
    
    x = if File.exists? dailyfile then dailyfile
    else
      'messagesp[date]/message(id, tags, from, to, subject, date, txt_filepath, html_filepath)'
    end
    
    @dd = DynarexDaily.new x, {dir_archive: :yearly}

  end

  def store messages

    messages.each do |msg| 

      subject = msg[:subject]
      title = subject.gsub(/\W+/,'-')[0,30].sub(/-$/,'')
      a = @dd.find_all_by_subject subject
      
      ordinal = a.any? ? '.' + a.length.to_s : ''
      txt_file = title + ordinal + '.txt'
      html_file = title + ordinal + '.html'

      id = msg[:id]
      next if @dd.find_by_id id

      path = archive()      
      txt_filepath = File.join(path, txt_file)
      html_filepath = File.join(path, html_file)
      
      @dd.create msg.merge(txt_filepath: txt_filepath, \
                                                html_filepath: html_filepath)

      FileUtils.mkdir_p path
      File.write txt_filepath, msg[:body_text]
      File.write html_filepath, msg[:body_html]
      
    end

    @dd.save
  end
  
  private
  
  def archive()
    
    t = Time.now
    path = File.join ['archive', t.year.to_s, \
                          Date::MONTHNAMES[t.month].downcase[0..2], t.day.to_s]

  end

end
