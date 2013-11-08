Introducing the Offline Mail Helper (OMAH) gem


Example:

    require 'mail'
    require 'omah'

    Mail.defaults do
      retriever_method :pop3, { :address             => "192.168.4.189",
                                :port                => 110,
                                :user_name           => 'james',
                                :password            => 'password',
                                :enable_ssl          => false }
    end

    email = Mail.all

    messages = email.inject([]) do |r, msg|

      r << {
        id:         msg.message_id,
        from:       msg.from.join(', '),
        to:         msg.to.join(', '),
        subject:    msg.subject,
        date:       msg.date.to_s,
        body_text:  msg.text_part.body.decoded,
        body_html:  msg.html_part.body.decoded
      }

    end

    o = Omah.new

    # messages are stored to the file dynarexdaily.xml
    o.store messages

The Omah gem (which is currently in development) is designed to store a copy of email messages in a file directory.

omah gem mail archive email
