=begin
This script will suspend all Agents in the account(s) listed.
This uses the Users endpoint. More info at http://developer.zendesk.com/documentation/rest_api/users.html

Rachel Wolthuis
Zendesk
April 2014
=end

require 'curb'
require 'open-uri'
require 'json'
require 'progress_bar'

class Suspend

  ACCOUNTS = [
    # account one
    {
      :subdomain => '<subdomain>', #eg: 'support' if url is support.zendesk.com
      :email     => '<email>', #email address of admin
      :api_token => '<token>' #account API token
    }
    #uncomment the block below to add another account.
    #the block can be compied and pasted

    # ,# account two
    # {
    #   :subdomain => '<domain>',
    #   :email     => '<email address>',
    #   :api_token => '<token>'
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

    url = "https://#{subdomain}.zendesk.com/api/v2/users.json?role[]=agent"
    result = open(url, :http_basic_authentication => ["#{email}/token", token])

    users_array = JSON.parse(result.read)["users"]

    agent_ids = users_array.map do |user|
      {
        :id => user['id']
      }
    end

    return agent_ids
  end

  def suspend_agents_for(account, agents)
    subdomain = account[:subdomain]
    email     = account[:email]
    token     = account[:api_token]
    bar       = ProgressBar.new(agents.length)

    agents.each do |agent|
      #Right now I'm just using curb to get the agent. How do I do a put call?
      c = Curl::Easy.new("https://#{subdomain}.zendesk.com/api/v2/users/#{agent[:id]}.json")
      c.http_auth_types = :basic
      c.username = "#{email}/token"
      c.password = token
      c.perform
      puts c.body_str

      sleep 0.1 #progress bar
      bar.increment!
    end
    puts "-- #{agents.length} Agents suspended! --"

  end

end

run = Suspend.new
run.fetch!
