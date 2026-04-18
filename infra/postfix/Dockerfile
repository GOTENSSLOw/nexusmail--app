FROM alpine:3.21

RUN apk add --no-cache \
    postfix \
    bash \
    shadow

EXPOSE 25

COPY main.cf.template /etc/postfix/main.cf.template
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["postfix", "start-fg"]
