FROM haproxy:lts

COPY --chown=haproxy:haproxy ./boot.sh /boot.sh

CMD ["/boot.sh"]
