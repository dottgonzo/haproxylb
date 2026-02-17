FROM haproxy:lts

USER root
COPY ./boot.sh /boot.sh
RUN chown haproxy:haproxy /usr/local/etc/haproxy/
USER haproxy

CMD ["/boot.sh"]
