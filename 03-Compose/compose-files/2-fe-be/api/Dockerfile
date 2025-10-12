FROM node
WORKDIR /app

COPY package*.json .
COPY . .

RUN npm i

EXPOSE 3000

CMD node server.js