# Postfux

Magical script to help filtering crap.

## TL;DR

Plugs into postfix filtering flow, parses the mail in a jail and throws it away if needed.

Currently throwing away mails containing one zip attachement with a file which name ends with .js, .vbs or .wsf. 

## How's things

Magic diagram explaining the magic:

```
📧 -> Postfix -> [ filter.rb ] -> if (status == 'ok' ||error )  -> Postfix -> 📧  delivered
                   |        ^     |
                   |        |     + else -> /dev/null
           POST /?mail=📧   |
                   |        |
                   |   {'status':'ok'}
                   v        |
                  [ server.rb ]
```

Basically we wanted to have a way to parse the 📧 body and inspect attachments, while doing that in a restricted environment.

Here `server.rb` runs as a daemon inside a `firejail`. `filter.rb` is called by postfix, and asks the `server.rb` whether the 📧 is bad or not.

## Install

    apt-get install ruby-mail ruby-zip firejail

Make a new user:

    adduser --system --no-create-home  --disabled-password --disabled-login  postfux

Get dat code

    cd /somewhere/safe
    git clone https://github.com/conchyliculture/postfux
    mkdir postfux/pid
    chown postfux postfux/filter.rb
    chown postfux: postfux/pid
    chmod u+x postfux/filter.rb


Run dat code

    su -c "/bin/bash ./postfux-start.sh" -s /bin/sh  postfux

Make sure dat code runs

    crontab -u postfux -e
    @restart    cd /somewhere/safe/postfux ; sh postfux-start.sh
    0 * * * *   cd /somewhere/safe/postfux ; sh postfux-start.sh


Then edit your `/etc/postfix/master.cf`

    smtp      inet  n       -       -       -       -       smtpd
        -o content_filter=filter:dummy

    # .....

    filter    unix  -       n       n       -       10      pipe
        flags=Rq user=postfux null_sender=
        argv=/somewhere/safe/postfux/filter.rb -f ${sender} -- ${recipient}

    # postfix reload

