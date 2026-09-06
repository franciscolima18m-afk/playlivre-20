# Etapa 1: compilar o Flutter
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copiar arquivos de dependências
COPY pubspec.yaml pubspec.lock* ./

# Baixar dependências
RUN flutter pub get

# Copiar o restante do projeto
COPY . .

# Compilar para Web
RUN flutter build web --release


# Etapa 2: servidor
FROM nginx:alpine

# Remover página padrão
RUN rm -rf /usr/share/nginx/html/*

# Copiar aplicativo compilado
COPY --from=build /app/build/web /usr/share/nginx/html

# Configuração do Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Porta do Render
EXPOSE 10000

# Iniciar servidor
CMD ["nginx", "-g", "daemon off;"]
