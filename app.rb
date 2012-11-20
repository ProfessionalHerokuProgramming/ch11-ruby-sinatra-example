# app.rb
require "twilio-ruby"
require 'sinatra'
require 'builder'
require 'digest/md5'
  
# Your Twilio authentication credentials
ACCOUNT_SID = ENV['TWILIO_ACCOUNT_SID']
ACCOUNT_TOKEN = ENV['TWILIO_AUTH_TOKEN']

# Your verified Twilio number
CALLER_ID = ENV['TWILIO_VERIFIED_PHONE_NO']

# Salt for making the hash used for passing the PIN unguessable.  You should
# change this to something different, like a random phrase.
SALT = 'mY5@Lt'

get '/' do
    erb :index
end

post '/pin_entry' do
    # Generate random number and translate to four digit PIN and hash it
    random_number = Random.rand(10000)
    pin = "%04d" % random_number
    @pin_md5 = Digest::MD5.hexdigest(pin + SALT)

    if params['number'].empty?
        redirect "/?msg=Invalid%20phone%20number"
        return
    end

    # parameters sent to Twilio REST API
    data = {
        :from => CALLER_ID,
        :to => params['number'],
        :body => 'This is an automated message from the SMS Phone ' +
            'Verification system.  Your PIN is ' + pin + '.'
    }
    
    begin
        # Use Twilio's REST API to send SMS message
        client = Twilio::REST::Client.new(ACCOUNT_SID, ACCOUNT_TOKEN)
        client.account.sms.messages.create data
    rescue StandardError => bang
        redirect "/?msg=" + URI.escape('Error ' + bang.to_s())
        return
    end

    erb :pin_entry
end

post '/verify' do
    # Check PIN entered against hash of PIN generated
    if params['pin'] != Digest::MD5.hexdigest(params['entry'] + SALT)
        redirect "/?msg=" + URI.escape('Incorrect PIN entered.  Try again.')
    end
  
    erb :verify
end
