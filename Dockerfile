FROM haproxy:2.3
CMD /boot.sh
RUN apt update && apt install -y nodejs
COPY ./boot.js /boot.js
COPY ./boot.sh /boot.sh