FROM ubuntu:latest as build
WORKDIR /app

RUN apt-get update && apt-get upgrade -y && apt-get -y install wget curl git unzip xz-utils zip libglu1-mesa && \
    wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.0-stable.tar.xz && \
	tar xf flutter_linux_3.29.0-stable.tar.xz -C ~/ && \
	git config --global --add safe.directory /root/flutter && \
	rm flutter_linux_3.29.0-stable.tar.xz
ENV PATH="$PATH:/root/flutter/bin"


COPY . .
RUN flutter pub get && dart run flutter_iconpicker:generate_packs --packs material && flutter build web --no-tree-shake-icons

FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]