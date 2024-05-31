zip -r ../dist.zip ../dist
scp ../dist.zip root@81.70.52.148:/var/www/asahi-blog/
ssh root@81.70.52.148 "cd /var/www/asahi-blog/ && rm -rf dist && unzip -o ./dist.zip && rm -f ./dist.zip"
cd ../
DEL dist.zip