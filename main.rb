require 'mechanize'
require 'pp'
require 'csv'

=begin

Login Page:
Url: https://www.okcupid.com/login
input '#user'
input '#pass'

Message URL
http://www.okcupid.com/messages
Close popup '#close_save_box'  # dont need to deal with this because I can click on links

http://www.okcupid.com/messages?folder=2
increment by 30
http://www.okcupid.com/messages?low=1&folder=2
http://www.okcupid.com/messages?low=271&folder=2

to go to a single conversation. ".subject"  or possibly "#messages p" it has an onclick event.

----

Individual string of message:
Photo: ".photo"  is a 'a' tag 'title' attribute has the username
Message: '.message_body'. 'div' tag. use <br> for new lines
Timestamp: '.fancydate' span, the time stamp is in a Row.

=end


def single_convo(convo, csv)
  user_names = []
  photos = convo.search('.photo')
  photos.each do |photo|
    user_names << photo.attr('title')
  end

  date_strings = []
  dates = convo.search('.fancydate')
  dates.each do |date|
    date_strings << date.content
  end

  messages = []
  message_bodies = convo.search('.message_body')
  message_bodies.each do |message|
    messages << message.content
  end

  csv << user_names
  csv << date_strings
  csv << messages

end

def single_page(offset, csv, agent)
  url = "http://www.okcupid.com/messages?low=" + offset.to_s + "&folder=2"
  messages_page = agent.get(url)

  thread_list = messages_page.search("#messages li>p")

  thread_list.each do |thread|
    link_string = thread.attributes['onclick'].value
    link_string.slice!("window.location='")
    link_string.slice!("';")
    link = "http://www.okcupid.com" + link_string

    convo = agent.get(link)
    single_convo(convo, csv)
  end

end

def start(username, password)
  agent = Mechanize.new
  agent.user_agent_alias = "Mac Safari"
  page = agent.get("https://www.okcupid.com/login")
  form = page.forms.first
  form['username'] = username
  form['password'] = password
  form.submit

  offset = 1
  CSV.open('messages.csv', 'w') do |csv|

    #from 1 to 271
    while offset < 300  do
      puts "starting offset " + offset.to_s + " ... "
      single_page(offset, csv, agent)
      offset += 30
    end
  end
end

if ARGV.length > 1
  username = ARGV[0]
  pass = ARGV[1]
  puts "username: " + username
  puts "password: " + pass
  start(username, pass)
end


