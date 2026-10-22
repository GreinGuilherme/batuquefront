FROM nginx:alpine
  
  # Limpa o diretório padrão do Nginx
RUN rm -rf /usr/share/nginx/html/*
  
  # Copia os arquivos compilados pelo passo "flutter build web" do GitHub Actions
COPY build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]