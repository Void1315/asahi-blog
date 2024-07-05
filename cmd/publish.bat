zip -r ../dist.zip ../dist
scp ../dist.zip asahi@81.70.52.148:/home/asahi/work/asahi-blog/
ssh asahi@81.70.52.148 "cd /home/asahi/work/asahi-blog/ && rm -rf dist && unzip -o ./dist.zip && rm -f ./dist.zip"
cd ../
DEL dist.zip