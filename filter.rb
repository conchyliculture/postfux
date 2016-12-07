#!/usr/bin/ruby
# apt install ruby-mail ruby-zip
#
# This is called by Postfix. It uses server.rb to check the mail
# and we drop or reroute it depending on the badness.

require "net/http"
require "json"
require "open3"
require "syslog/logger"

$SYSLOG = Syslog.open(__FILE__, Syslog::LOG_PID, Syslog::LOG_MAIL)


def do_sendmail(content)
    _stdout, _stderr, status = Open3.capture3("/usr/sbin/sendmail", "-G", "-i", *ARGV, stdin_data:content)
    return status.exitstatus
end

def send_to_filter(content)
    begin
        status = JSON.parse(Net::HTTP.post_form(URI.parse('http://localhost:12345/'), {'mail' => content}).body)["status"]
        if status != "ok"
            $SYSLOG.info("Filter said this is a bad email: '#{status}', dropping mail.")
            return false
        end
    rescue Exception => e
        $SYSLOG.info("Got an error sending mail to filter: '#{e.message}', delivering mail as usual.")
    end
    return true
end

mail_content = STDIN.read()

if not send_to_filter(mail_content)
    exit 0 # Move along, nothing to see there, we need to return 0 otherwise the mail would bounce
end

return_status = do_sendmail(mail_content)
exit return_status
