#!/usr/bin/ruby
# apt install ruby-mail ruby-zip
#
# This is supposed to run all the time.
# It will run a WEBrick server, accepting POST forms
# with a "mail" query, containing the content of the mail
# to check
#
# It will either return a JSON encoded
# {'status': 'ok'}
# if the mail looks okay
# {'status': 'reason why this mail sucks'}
# otherwise

require "json"
require "webrick"
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


# This daemonize thing is stolen from
# http://codeincomplete.com/posts/ruby-daemons/
def write_pid(pidfile)
    if pidfile
        begin
            File.open(pidfile, ::File::CREAT | ::File::EXCL | ::File::WRONLY){|f| f.write("#{Process.pid}") }
            at_exit { File.delete(pidfile) if File.exists?(pidfile) }
        rescue Errno::EEXIST
            check_pid(pidfile)
            retry
        end
    end
end

def check_pid(pidfile)
    if pidfile
        case pid_status(pidfile)
        when :running, :not_owned
            puts "A server is already running. Check #{pidfile}"
            exit(1)
        when :dead
            File.delete(pidfile)
        end
    end
end

def pid_status(pidfile)
    return :exited unless File.exists?(pidfile)
    pid = ::File.read(pidfile).to_i
    return :dead if pid == 0
    Process.kill(0, pid)            # check process status
    :running
rescue Errno::ESRCH
	:dead
rescue Errno::EPERM
	:not_owned
end

def daemonize(chdir)
    exit if fork
    Process.setsid
    exit if fork
    Dir.chdir chdir
end

pidfile = "#{__FILE__}.pid"
dir = File.dirname(__FILE__)

check_pid(pidfile)
daemonize(dir)
write_pid(pidfile)

server = WEBrick::HTTPServer.new(
    :Port => 12345,
    :BindAddress => "127.0.0.1",
    :DocumentRoot => "/dev/null", 
    :Logger => WEBrick::Log.new("/dev/null"),
    :AccessLog => []
)

trap("INT") {
        server.shutdown
}

server.mount_proc '/' do |req, res|
    mail_body =  req.query["mail"]
    response = JSON.generate({'status' => 'ok'})
    begin
        Postfux.filter(mail_body)
    rescue Postfux::FilterError => e
        $SYSLOG.info("Dropping mail: #{e.message}") 
        response = JSON.generate({'status' => e.message })
    end
    res.body = response
end

server.start
