run image with:


docker run --rm --name nginxweb --label-file ./labels --net [Traefik network ID] -d nginx

put it in the traefik network
no need to export ports, traefik will do so
