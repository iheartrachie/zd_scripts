=begin
This script will suspend all Agents and Admins (non-owners) in the account(s) listed.
This uses the Users endpoint. More info at http://developer.zendesk.com/documentation/rest_api/users.html

Rachel Wolthuis
Zendesk
April 2014
=end

require 'zendesk_api'
require 'open-uri'
require 'json'
require 'progress_bar'

class Suspend

  ACCOUNTS = [
    # account one
    {
      :subdomain => '<subdomain>', #eg: 'support' if url is support.zendesk.com
      :email     => '<email>', #email address of admin
      :api_token => '<token>', #account API token
      :owner_id  => <user_id> #user_id for the owner of the account
    }
    #uncomment the block below to add another account.
    #the block can be compied and pasted

    # ,# account two
    # {
    #   :subdomain => '<domain>',
    #   :email     => '<email address>',
    #   :api_token => '<token>',
    #   :owner_id  => '<user_id>'
    # }
  ]

  def initialize
  end

  def fetch!
    ACCOUNTS.each do |account|
      puts "-- Creating a list of agents & admins to suspend on #{account[:subdomain]}.zendesk.com --"
      agents = get_agents_for(account)
      suspend_agents_for(account, agents)
    end
  end

  def get_agents_for(account)
    subdomain = account[:subdomain]
    email     = account[:email]
    token     = account[:api_token]

    url = "https://#{subdomain}.zendesk.com/api/v2/users.json?role[]=agent&role[]=admin"
    result = open(url, :http_basic_authentication => ["#{email}/token", token])
    returned = JSON.parse(result.read)
    next_page = returned['next_page']
    users_array = returned['users']

    while (next_page != nil)
      result_next = open(next_page, :http_basic_authentication => ["#{email}/token", token])
      returned_next = JSON.parse(result_next.read)
      next_page = returned_next['next_page']
      returned_next['users'].each do |user|
        users_array << user
      end
      
    end

    puts "-- #{users_array.length} agents & admins to be suspended on #{account[:subdomain]}.zendesk.com --"
    return users_array
  end

  def suspend_agents_for(account, agents)
    subdomain = account[:subdomain]
    email     = account[:email]
    token     = account[:api_token]
    owner     = account[:owner_id]
    bar       = ProgressBar.new(agents.length)
    suspended_agents = 0

    client = ZendeskAPI::Client.new do |config|
      config.url = "https://#{subdomain}.zendesk.com/api/v2"
      config.username = "#{email}/token"
      config.token = token
    end

    puts "-- Suspending all admins & agents on #{account[:subdomain]}.zendesk.com --"

    agents.each do |agent|
      if(agent['role'] != 'end-user' && agent['id'] != owner)
        found_user = client.users.find(:id => agent['id'])
        found_user.suspended = true
        found_user.save
        suspended_agents += 1
      else
        puts "!! User #{agent['id']} is an end-user or the Owner. User skipped. !!"
      end
        sleep 0.1 #progress bar
        bar.increment! 
    end
    puts "-- #{suspended_agents} admins & agents on #{account[:subdomain]}.zendesk.com have been suspended --"

  end

end

run = Suspend.new
run.fetch!