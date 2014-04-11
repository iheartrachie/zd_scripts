=begin
This script will suspend all Agents in the account(s) listed.
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
      :subdomain => '<domain>', #eg: 'support' if url is support.zendesk.com
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
      puts "-- Suspending all Agents on #{account[:subdomain]}.zendesk.com ---"
      agents = get_agents_for(account)
      suspend_agents_for(account, agents)
    end
  end

  def get_agents_for(account)
    subdomain = account[:subdomain]
    email     = account[:email]
    token     = account[:api_token]

    #couldn't figure out how to get the agent & admins back using the app
    #need to paginate the results so that additional users are added to the agent_ids array
    #see next_page items below

    url = "https://#{subdomain}.zendesk.com/api/v2/users.json?role[]=agent&role[]=admin"
    result = open(url, :http_basic_authentication => ["#{email}/token", token])
    #next_page = JSON.parse(result.read)["next_page"] <-- not sure the syntax to get that url
    users_array = JSON.parse(result.read)["users"]

    # while (next_page != null)
    #   open(next_page, :http_basic_authentication => ["#{email}/token", token])
    #   users_array << JSON.parse(result.read)["users"]
    # end

    agent_ids = users_array.map do |user|
      {
        :id => user['id'],
        :role => user['role']
      }
    end

    return agent_ids
    puts agent_ids.each(agent_id[:id])
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

    agents.each do |agent|
      if(agent[:role] != 'end-user' && agent[:id] != owner)
        found_user = client.users.find(:id => agent[:id])
        found_user.suspended = false
        found_user.save
        suspended_agents += 1
      else
        puts "User #{agent[:id]} is an end-user or and the Owner, not an Agent/Admin. User skipped."
      end
        sleep 0.1 #progress bar
        bar.increment! 
    end
    puts "-- #{suspended_agents} Agents suspended! --"

  end

end

run = Suspend.new
run.fetch!