FROM node:20-alpine AS base

# prepare
RUN npm install -g pnpm

# install
FROM base AS dependencies
WORKDIR /usr/src/app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install

# build
FROM base AS build
WORKDIR /usr/src/app
COPY . .
COPY --from=dependencies /usr/src/app/node_modules ./node_modules
RUN pnpm build && pnpm prune --prod

# Deploy
FROM base AS deploy
COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./package.json
COPY --from=build /usr/src/app/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=build /usr/src/app/prisma ./prisma

RUN pnpm i prisma && pnpm prisma generate

EXPOSE 3333

CMD ["pnpm", "start"]
