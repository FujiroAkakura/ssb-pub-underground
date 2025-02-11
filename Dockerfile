FROM node:23-bullseye
RUN apt update

LABEL org.opencontainers.image.authors="FujiroAkakura@proton.me"
WORKDIR /code

RUN npm install -g ssb-server@15.3.0

EXPOSE 8008

HEALTHCHECK --interval=30s --timeout=30s --start-period=10s --retries=10 \
  CMD ssb-server whoami || exit 1
ENV HEALING_ACTION=RESTART

#ENTRYPOINT [ "/tini", "--", "ssb-server" ]
ENTRYPOINT ["ssb-server"]
CMD [ "start" ]
