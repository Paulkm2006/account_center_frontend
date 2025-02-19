FROM alpine:latest as build
WORKDIR /app

RUN apk update && apk add curl git unzip xz zip mesa-gl bash clang cmake pkgconf samurai gtk+3.0-dev && \
    wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.0-stable.tar.xz && \
	tar xf flutter_linux_3.29.0-stable.tar.xz -C ~/ && \
	rm flutter_linux_3.29.0-stable.tar.xz
ENV PATH="$PATH:/root/flutter/bin"

COPY . .
RUN flutter doctor -v && flutter pub get && flutter build web --wasm --no-tree-shake-icons

FROM nginx:1-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]