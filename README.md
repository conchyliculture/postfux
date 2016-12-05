# Postfux

Magical script to help filtering crap.

## Install

    apt-get install ruby-mail ruby-zip

Make a new user:

    adduser --system --no-create-home  --disabled-password --disabled-login  postfix-filter

Copy `filter.rb` to `FILTER_PATH`, then do:

    chown postfix-filter filter.rb
    chmod u+x filter.rb

Then edit your `/etc/postfix/master.cf`

    smtp      inet  n       -       -       -       -       smtpd
        -o content_filter=filter:dummy

    # .....

    filter    unix  -       n       n       -       10      pipe
        flags=Rq user=postfix-filter null_sender=
        argv=/etc/postfix/filter.rb -f ${sender} -- ${recipient}

## TODO

Firejail dat shit
