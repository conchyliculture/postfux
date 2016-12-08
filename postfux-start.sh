firejail --private \
    --noprofile \
    --privatedev \
    --nosound \
    --no3d \
    --seccomp \
    --caps.drop=all \
    --name=postfux \
    -- \
    ruby server.rb
