FROM haproxy:lts

COPY ./boot.sh /boot.sh

CMD ["/boot.sh"]
