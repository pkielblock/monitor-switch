FROM oven/bun:1-debian
RUN apt-get update \
 && apt-get install -y --no-install-recommends ddcutil \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package.json server.ts config.json ./
COPY public ./public
ENV PORT=7580
EXPOSE 7580
CMD ["bun", "server.ts"]
