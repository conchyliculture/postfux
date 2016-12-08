# Postfux

Magical script to help filtering crap.

## Install

    apt-get install ruby-mail ruby-zip firejail

Make a new user:

    adduser --system --no-create-home  --disabled-password --disabled-login  postfux

Get dat code

    cd /somewhere/safe
    git clone https://github.com/conchyliculture/postfux
    chown -R postfux: postfux
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
        flags=Rq user=postfix-filter null_sender=
        argv=/somewhere/safe/postfux/filter.rb -f ${sender} -- ${recipient}

    # postfix reload

