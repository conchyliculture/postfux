#!/usr/bin/ruby
# apt install ruby-mail ruby-zip

require "open3"
require "syslog/logger"

$SYSLOG = Syslog.open(__FILE__, Syslog::LOG_PID, Syslog::LOG_MAIL)

module Postfux 
    class FilterError < Exception ; end

    def Postfux.check_zip(string)
        require "zip"
        Zip::File.open_buffer(string) do |z|
            z.each do |entry|
                case entry.name
                when /\.vbs$/i
                    raise FilterError.new("File named /\\.vbs$/ in a zip")
                when /\.js$/i
                    raise FilterError.new("File named /\\.js$/ in a zip")
                end
            end
        end
    end

    def Postfux.filter(input)
        # Fire all tests here
        require "mail"
        mail = Mail.read_from_string(input)
        if mail.has_attachments?
            mail.attachments.each do |a|
                Postfux.check_zip(a.body.to_s)
            end
        end
    end
end

def do_sendmail(content)
    _stdout, _stderr, status = Open3.capture3("/usr/sbin/sendmail", "-G", "-i", *ARGV, stdin_data:content)
    return status.exitstatus
end

mail_content = STDIN.read()

begin
    Postfux.filter(mail_content)
rescue Postfux::FilterError => e
    $SYSLOG.info("Dropping mail: #{e.message}") 
    exit 0 # Everything is fine, we need to return 0 otherwise the mail would bounce
end

return_status = do_sendmail(mail_content)
exit return_status
