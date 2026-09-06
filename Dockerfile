# Etapa 1: compilar o Flutter
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copiar os arquivos do projeto
COPY pubspec.yaml pubspec.lock* ./

# Baixar dependências
RUN flutter pub get

# Copiar o restante do aplicativo
COPY . .

# Criar a configuração Web do Flutter
RUN flutter create . --platforms web

# Compilar para Web
RUN flutter build web --release


# Etapa 2: servidor para o aplicativo
FROM nginx:alpine

# Remover página padrão do nginx
RUN rm -rf /usr/share/nginx/html/*

# Copiar aplicativo compilado
COPY --from=build /app/build/web /usr/share/nginx/html

# Copiar configuração do Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Configurar a porta do Render
EXPOSE 10000

# Iniciar servidor
CMD ["nginx", "-g", "daemon off;"]
