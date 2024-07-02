tar -zcvf ./dist.tar.gz ./dist
scp ./dist.tar.gz asahi@81.70.52.148:/home/asahi/work/asahi-blog/
ssh asahi@81.70.52.148 "cd /home/asahi/work/asahi-blog/ && rm -rf dist && tar -zxvf ./dist.tar.gz && rm ./dist.tar.gz"
rm ./dist.tar.gz
