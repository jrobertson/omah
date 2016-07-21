#!/usr/bin/env ruby

# file: omah.rb
# title: Offline Mail Helper

require 'zip'
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
  
  def initialize(user: 'user', filepath: '.', \
             options: {xslt: 'listing.xsl'}, plugins: [], webpath: '/email' )

    @user = user
    @xslt = options[:xslt]
    @css = options[:css]
    @variables ||= {}

    @filepath_user = File.expand_path(File.join(filepath, @user))
    @webpath_user = webpath +'/' + @user

    Dir.chdir filepath

    FileUtils.mkdir_p @filepath_user # attempt to 
    #                                     mkdir regardless if it already exists

    Dir.chdir @filepath_user
    
    dailyfile = 'dynarexdaily.xml'
    
    x = if File.exists? dailyfile then dailyfile
    else
      'messages[date]/message(msg_id, tags, from, to, subject, date, ' \
        + 'txt_filepath, html_filepath, attachment1, attachment2, attachment3)'
    end
    
    @dd = DynarexDaily.new x, dir_archive: :yearly
    
    
    # intialize plugins
        
    @plugins = plugins.inject([]) do |r, plugin|
      
      name, settings = plugin
      return r if settings[:active] == false and !settings[:active]
      
      klass_name = 'OmahPlugin' + name.to_s.split(/[-_]/).map{|x| x.capitalize}.join

      r << Kernel.const_get(klass_name).new(settings: settings, variables: @variables)

    end    

  end

  def store(messages)

    messages.each.with_index do |msg,i|

      subject = msg[:subject]
      
      title = subject.gsub(/\W+/,'-')[0,30].sub(/-$/,'')

      a = @dd.all.select {|x| x.subject == subject}

      ordinal = a.any? ? '.' + a.length.to_s : ''

      x_file = title + ordinal
      txt_file = title + ordinal + '.txt'      
      html_file = title + ordinal + '.html'
      kvx_file = title + ordinal + '.kvx'      

      id = msg[:msg_id]
      next if @dd.find_by_msg_id id

      path = archive()
      x_filepath = File.join(path, x_file)      
      txt_filepath = File.join(path, txt_file)
      html_filepath = File.join(path, html_file)
      kvx_filepath = File.join(path, kvx_file)
      

      FileUtils.mkdir_p path

      if msg[:raw_source] then
        File.write File.join(@filepath_user, x_filepath + '.eml'), \
                    msg[:raw_source]
      end
      
      header = %i(from to subject).inject({}) {|r,x| r.merge(x => msg[x]) }
      Kvx.new(header).save File.join(@filepath_user, x_filepath + '.kvx')
      
      File.write File.join(@filepath_user, x_filepath + '.txt'), \
                                      text_sanitiser(msg[:body_text].to_s)

      File.write File.join(@filepath_user, x_filepath + '.html'), \
                                      html_sanitiser(msg[:body_html].to_s)
      
      parts_path = []
      
      # save the attachments
      if msg[:attachments].length > 0 then
        
        attachment_path = File.join(path, title + ordinal)
        FileUtils.mkdir_p attachment_path
        
        if msg[:attachments].length < 4 then
          
          msg[:attachments].each.with_index do |x, i|
            
            name, buffer = x
            parts_path[i] = File.join(attachment_path, name.gsub('/',''))
            begin
              File.write File.join(@filepath_user, parts_path[i]), buffer
            rescue
              puts ($!)
            end
            
          end
          
        else
          
          # make a zip file and add the attachments to it
          
          zipfile = File.join(@filepath_user, attachment_path, title[0,12].downcase + '.zip')
          parts_path[0] = zipfile

          Zip::File.open(zipfile, Zip::File::CREATE) do |x|

            msg[:attachments].each do |filename, buffer| 
              x.get_output_stream(filename) {|os| os.write buffer }
            end

          end          
          
        end        
        

      end
      
      msg.delete :attachments

      h = msg.merge(txt_filepath: txt_filepath, \
                       html_filepath: html_filepath)
      parts_path.each.with_index do |path, i|
        h.merge!("attachment#{i+1}" => @webpath_user + '/' + path)
      end

      @dd.create h
      
      @plugins.each do |x| 
        x.on_newmessage(h) if x.respond_to? :on_newmessage 
      end

    end
    
    if @xslt then
      
      unless File.exists? @xslt then
        File.write File.expand_path(@xslt), fetch_file(@xslt)
        File.write File.expand_path(@css), fetch_file(@css) if @css and \
                                                          not File.exists? @css
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
    
    File.write File.join(@filepath_user, 'dynarexdaily.xml'), \
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
    
    e.attributes[:css_class] = NoVowels.compact(e.text[/[^@]+$/].gsub('.',''))
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