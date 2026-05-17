# Multistage
# Stage 1
FROM node:20-alpine AS builder
WORKDIR /build
COPY package*.json ./
RUN npm install
COPY . .
ARG VITE_VENTAS_API_URL
ARG VITE_DESPACHOS_API_URL
ENV VITE_VENTAS_API_URL=${VITE_VENTAS_API_URL}
ENV VITE_DESPACHOS_API_URL=${VITE_DESPACHOS_API_URL}
RUN npm run build

# Stage 2
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /build/dist /usr/share/nginx/html
EXPOSE 80
