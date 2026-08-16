# kk-payments v1.2.0 — minimal Node.js payments service.
FROM node:20-alpine
WORKDIR /app
COPY package.json ./
COPY payments.js receipts.js server.js ./
ENV APP_VERSION=1.2.0
EXPOSE 3001
USER node
CMD ["node", "server.js"]
