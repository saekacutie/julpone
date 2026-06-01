FROM openresty/openresty:alpine
RUN apk add --no-cache ca-certificates wget unzip netcat-openbsd openssh-server curl python3 py3-pip shadow bash sudo
RUN pip3 install --break-system-packages --no-cache-dir websockets

RUN wget -qO /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip -p /tmp/xray.zip xray > /usr/local/bin/xray && \
    chmod +x /usr/local/bin/xray && rm -rf /tmp/xray.zip

RUN ssh-keygen -A && \
    mkdir -p /run/sshd && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "Port 2222" >> /etc/ssh/sshd_config && \
    echo "ClientAliveInterval 30" >> /etc/ssh/sshd_config && \
    echo "ClientAliveCountMax 3" >> /etc/ssh/sshd_config && \
    echo "TCPKeepAlive yes" >> /etc/ssh/sshd_config && \
    echo "UseDNS no" >> /etc/ssh/sshd_config && \
    echo "GSSAPIAuthentication no" >> /etc/ssh/sshd_config && \
    echo "root:saeka-tojirp" | chpasswd && \
    useradd -m -s /bin/bash saeka && \
    echo "saeka:saeka-tojirp" | chpasswd && \
    usermod -aG wheel saeka

COPY ws-bridge.py /usr/local/bin/ws-bridge.py
RUN chmod +x /usr/local/bin/ws-bridge.py

COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY index.html /usr/local/openresty/nginx/html/index.html
EXPOSE 8080

CMD /usr/local/bin/xray run -c /etc/xray.json & \
    /usr/sbin/sshd & \
    LISTEN_PORT=2223 TARGET_PORT=2222 python3 /usr/local/bin/ws-bridge.py & \
    while ! nc -z 127.0.0.1 10000; do sleep 0.1; done && \
    while ! nc -z 127.0.0.1 10001; do sleep 0.1; done && \
    while ! nc -z 127.0.0.1 10002; do sleep 0.1; done && \
    while ! nc -z 127.0.0.1 10003; do sleep 0.1; done && \
    while ! nc -z 127.0.0.1 10004; do sleep 0.1; done && \
    while ! nc -z 127.0.0.1 10005; do sleep 0.1; done && \
    while ! nc -z 127.0.0.1 10006; do sleep 0.1; done && \
    while ! nc -z 127.0.0.1 10007; do sleep 0.1; done && \
    while ! nc -z 127.0.0.1 10008; do sleep 0.1; done && \
    while ! nc -z 127.0.0.1 10009; do sleep 0.1; done && \
    while ! nc -z 127.0.0.1 10010; do sleep 0.1; done && \
    while ! nc -z 127.0.0.1 10011; do sleep 0.1; done && \
    while ! nc -z 127.0.0.1 2223; do sleep 0.1; done && \
    /usr/local/openresty/bin/openresty -g 'daemon off;'
