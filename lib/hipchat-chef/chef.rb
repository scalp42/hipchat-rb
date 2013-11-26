require 'hipchat-chef'

#
# Provides a Chef exception handler so you can send information about
# chef-client failures to a HipChat room.
#
# Docs: http://wiki.opscode.com/display/chef/Exception+and+Report+Handlers
#
# Install - add the following to your client.rb:
#   require 'hipchat/chef'
#   hipchat_handler = HipChat::NotifyRoom.new("<api token>", "<room name>")
#   exception_handlers << hipchat_handler
#

module HipChat
  class NotifyRoom < Chef::Handler

    def initialize(api_token, room_name, notify_users=false, report_success=false, excluded_envs=[], override_colors={})
      @api_token = api_token
      @room_name = room_name
      @notify_users = notify_users
      @report_success = report_success
      @excluded_envs = excluded_envs
      @override_colors = override_colors
    end

    def report
      unless @excluded_envs.include?(node.chef_environment)
        msg = if run_status.failed? then "Failure on \"<b>#{node.name}</b>\" (<b>#{node.chef_environment}</b>, <b>#{node['ipaddress']}</b>):\n#{run_status.formatted_exception}"
              elsif run_status.success? && @report_success
                "Chef run on \"#{node.name}\" completed in #{run_status.elapsed_time.round(2)} seconds"
              else nil
              end

        @override_colors.default_proc = proc do |h, k|
          case k
            when String then sym = k.to_sym; h[sym] if h.key?(sym)
            when Symbol then str = k.to_s; h[str] if h.key?(str)
          end
        end

        color = if run_status.success?
                  @override_colors[:success].to_s || 'green'
                else
                  @override_colors[:failure].to_s || 'red'
                end

        if msg
          client = HipChat::Client.new(@api_token)
          client[@room_name].send('Chef', msg, :notify => @notify_users, :color => color)
        end
      end
    end
  end
end
