FROM alpine

RUN apk add --no-cache bash

WORKDIR /app

COPY script.sh .
RUN chmod +x script.sh

ENTRYPOINT ["./script.sh"]