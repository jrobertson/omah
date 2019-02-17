#!/usr/bin/env ruby

# file: omah.rb
# title: Offline Mail Helper

require 'nokorexi'
require 'dynarex-daily'
require 'novowels'

module Library

  def fetch_file(filename)

    lib = File.dirname(__FILE__)
    File.read File.join(lib,'..','stylesheet',filename)

  end
end

class Omah

  include Library
  include RXFHelperModule
  
  def initialize(user: 'user', filepath: '.', \
             options: {xslt: 'listing.xsl', url_base: 'http://localhost/' }, 
                 plugins: [], webpath: '/email', debug: false)

    
    puts 'inside Omah::initialize' if @debug
    
    @user = user
    @xslt = options[:xslt]
    @css = options[:css]
    @variables ||= {}

    @filepath_user = File.join(filepath, @user)
    @webpath_user = webpath +'/' + @user
    @url_base = options[:url_base] || '.'
    @debug = debug

    puts 'Omah::initialize filepath: ' + filepath.inspect if @debug
    
    FileX.chdir filepath

    puts 'Omah::initialize making directory ' + @filepath_user if @debug
    FileX.mkdir_p @filepath_user 

    FileX.chdir @filepath_user
    
    dailyfile = File.join(@filepath_user, 'dynarexdaily.xml')
    
    x = if FileX.exists? dailyfile then dailyfile

    else
      
      'messages[date, prev_date, next_date]/message(msg_id, tags, from, ' + \
      'to, subject, date, txt_filepath, html_filepath, attachment1, ' + \
      'attachment2, attachment3, attachments)'        

    end

    puts 'Omah::initialize before DynarexDaily' if @debug
    @dd = DynarexDaily.new x, dir_archive: :yearly, debug: @debug   
    puts 'Omah::initialize after DynarexDaily' if @debug
    # is it a new day?
    
    if @dd.records.empty? then
            
      date_yesterday = File.join(@filepath_user, 
                                (Date.today - 1).strftime("%Y/%b/%d").downcase)
      
      @dd.prev_date = File.join(@webpath_user, date_yesterday)
      
      # add the next_day field value to the previous day file
      
      file_yesterday = date_yesterday + '/index.xml'

      if FileX.exists? file_yesterday then
        
        dx_yesterday = Dynarex.new file_yesterday
        dx_yesterday.next_date = File.join(@webpath_user, 
                                      (Date.today).strftime("%Y/%b/%d").downcase)
        dx_yesterday.xslt = options[:archive_xsl] if options[:archive_xsl]
        dx_yesterday.save
      end
      
    end
    
    # intialize plugins
        
    puts 'Omah::initialize before plugins' if @debug
    
    @plugins = plugins.inject([]) do |r, plugin|
      
      name, settings = plugin
      
      puts 'Omah::initialize plugin: ' + name.inspect if @debug
      
      return r if settings[:active] == false and !settings[:active]
      
      klass_name = 'OmahPlugin' + name.to_s.split(/[-_]/)\
          .map{|x| x.capitalize}.join

      r << Kernel.const_get(klass_name).new(settings: settings, 
                                            variables: @variables, debug: @debug)

    end    

  end

  def store(messages)

    messages.each.with_index do |x,i|
      
      email, msg = x
      
      begin
        
        puts "i: %d msg: %s" % [i, msg] if @debug
        subject = msg[:subject] || ''
        
        title = subject.gsub(/\W+/,'-')[0,30].sub(/^-/,'').sub(/-$/,'')

        a = @dd.all.select {|x| x.subject == subject}

        ordinal = a.any? ? '.' + a.length.to_s : ''

        x_file = title + ordinal

        id = msg[:msg_id]

        next if @dd.find_by_msg_id id

        path = archive()

        x_filepath = File.join(path, x_file)            

        puts 'FileX.pwd ' + FileX.pwd if @debug
        puts 'Omah::store before mkdir_p path: ' + path.inspect if @debug
        FileX.mkdir_p path

        if msg[:raw_source] then
          FileX.write File.join(@filepath_user, x_filepath + '.eml'), \
                      msg[:raw_source]
        end

        header = %i(from to subject).inject({}) {|r,x| r.merge(x => msg[x]) }
        filepath = File.join(@filepath_user, x_filepath + '.kvx')
        Kvx.new(header, debug: false).save filepath
        
        txt_filepath = x_filepath + '.txt'
        FileX.write File.join(@filepath_user, txt_filepath), \
                                        text_sanitiser(msg[:body_text].to_s)

        html_filepath = x_filepath + '.html'
        FileX.write File.join(@filepath_user, html_filepath), \
                                        html_sanitiser(msg[:body_html].to_s)
        
        parts_path = []
        
        # save the attachments
        if msg[:attachments].length > 0 then
          
          attachment_path = File.join(path, title + ordinal)
          FileX.mkdir_p attachment_path
          
          msg[:attachments][0..2].each.with_index do |x, i|
            
            name, buffer = x
            parts_path[i] = File.join(attachment_path, name.gsub('/',''))
            begin
              FileX.write File.join(@filepath_user, parts_path[i]), buffer
            rescue
              puts ($!)
            end
            
          end          
          
          h[:attachments] = msg[:attachments].map(&:first)

        end
        
        msg.delete :attachments

        h = msg.merge(txt_filepath: txt_filepath, \
                        html_filepath: html_filepath)
        parts_path.each.with_index do |path, i|
          h.merge!("attachment#{i+1}" => @webpath_user + '/' + path)
        end
        
        if parts_path.any? then
          
          attachments = parts_path.map do |path|
            "<li><a href='%s'>%s</a></li>" % [@webpath_user + '/' + path, 
                                              File.basename(path)]
          end
          
          
html_page= %Q(
<html>
  <head>
    <title>#{title}</title>
    <meta content="">
    <style></style>
  </head>
  <body>
    <iframe src='../#{File.basename(html_filepath)}'></iframe>   
    <h2>attachments</h2>
    <ul>
      #{attachments.join("\n")}
    </ul>
  </body>
</html>
)

          FileX.write File.join(attachment_path, 'index.html'), html_page
          h[:html_filepath] = File.join(attachment_path, 'index.html')
        end

        h[:link] = File.join(@url_base, @webpath_user, html_filepath)

        @plugins.each {|x| x.on_newmessage(h) if x.respond_to? :on_newmessage }
        
        @dd.create h
      
      
        # remove the message from the server
        #jr250918 email.delete
        
      rescue
        puts 'Omah::store warning: ' + ($!).inspect
      end

    end
    
    if @xslt then
      
      unless FileX.exists? @xslt then
        FileX.write File.expand_path(@xslt), fetch_file(@xslt)
        FileX.write File.expand_path(@css), fetch_file(@css) if @css and \
                                                          not FileX.exists? @css
      end
      
      @dd.xslt = @xslt

    end
    
    
    doc = @dd.to_doc

    doc.root.xpath('records/message').each do |message|
      
      classify message.element('from')
      classify message.element('to')
      
    end

    @plugins.each do |x| 
      x.on_newmail(messages, doc) if x.respond_to? :on_newmail
    end
    
    FileX.write File.join(@filepath_user, 'dynarexdaily.xml'), \
                                                        doc.xml(pretty: true)
    
  end
  
  private
  
  def archive()
    
    t = Time.now
    path = File.join ['archive', t.year.to_s, \
                          Date::MONTHNAMES[t.month].downcase[0..2], t.day.to_s]

  end  
  
  def classify(e)
    
    s = e.text.to_s    
    return if s.empty?
    
    e.attributes[:css_class] = NoVowels.compact(s.gsub(/\W+/,''))
  end    

  def html_sanitiser(s)
    # Parsing HTML has proved problematic either way. Instead we will just 
    # return whatever is given.
=begin
    begin
      Rexle.new s
      s2 = s
    rescue
      doc = Nokorexi.new(s).to_doc
      s2 = doc.xml
    end
=end
    s
  end
  

  def text_sanitiser(s)
    # Parsing HTML has proved problematic either way. Instead we will just 
    # return whatever is given.
=begin    
    begin
      Rexle.new "<root>#{s}</root>"
      s2 = s
    rescue
      doc = Nokorexi.new(s).to_doc
      s2 = doc.xml
    end
=end
    s
  end
    

end
