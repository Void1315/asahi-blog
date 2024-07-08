---
title: 'Docker部署Gitlab'
description: '腾讯云服务器，Debian环境。2核4G云主机，使用Docker部署Gitlab-CE，并使用外部Nginx反向代理配置域名以及HTTPS协议。'
publishDate: '2024 07 2'
tags: ['Docker', 'Gitlab']
---

## 安装Gitlab CE版本

```bash
docker pull gitlab/gitlab-ce:latest # ce是社区版，也可以选择自己的版本安装
```

## 配置$GITLAB_HOME

&ensp;&ensp;&ensp;&ensp;我们需要一个配置目录，当`Docker`中的`Gitlab`容器启动时，会将配置文件、日志文件、数据文件挂载到这个目录中。这样我们可以在容器重启后，不会丢失数据。

&ensp;&ensp;&ensp;&ensp;并且可以方便的在宿主机中，修改`Gitlab`容器的配置文件。

首先在想要保存容器数据的目录下创建三个文件夹。

```bash
mkdir -p /srv/gitlab/{config,logs,data}
```

&ensp;&ensp;&ensp;&ensp;将`export GITLAB_HOME=/srv/gitlab`添加到`/etc/profile`中，然后执行`source /etc/profile`。

&ensp;&ensp;&ensp;&ensp;在终端中使用`echo $GITLAB_HOME`查看是否配置成功。

## 启动Gitlab容器

```bash
docker run -d -p 18443:443 -p 18080:80 -p 18022:22 --name gitlab --restart always -v $GITLAB_HOME/config:/etc/gitlab -v $GITLAB_HOME/logs:/var/log/gitlab -v $GITLAB_HOME/data:/var/opt/gitlab gitlab
```

&ensp;&ensp;&ensp;&ensp;这里面有几个重要的参数需要注意：

1. `-p 18443:443`，我们将宿主机的`18443`端口映射到`Gitlab`容器的`443`端口，这样我们就可以通过`https://ip:18443`访问`Gitlab`。
2. `-p 18080:80`，我们将宿主机的`18080`端口映射到`Gitlab`容器的`80`端口，这样我们就可以通过`http://ip:18080`访问`Gitlab`。
3. `-p 18022:22`，我们将宿主机的`18022`端口映射到`Gitlab`容器的`22`端口，这样我们就可以通过`ssh -p 18022 git@ip`访问`Gitlab`。

## 配置`SSL`证书

&ensp;&ensp;&ensp;&ensp;我们使用自行注册的证书来配置`https`协议。首先我们需要已经准备好的`SSL`证书。

```bash
# 需要注意，我们必须要将证书放在$GITLAB_HOME/config目录下，否则容器无法读取到证书。
cp xxx.top.pem /srv/gitlab/config/xxx.top.pem
cp xxx.top.key /srv/gitlab/config/xxx.top.key
```

## 配置`gitlab.rb`文件

&ensp;&ensp;&ensp;&ensp;在`$GITLAB_HOME/config`目录下，我们可以找到`gitlab.rb`文件，这个文件是`Gitlab`的配置文件。每当使用`gitlab-ctl reconfigure`命令时，`Gitlab`会读取这个文件的配置。并通过这个文件中的配置，生成`Gitlab`、`Nginx`、`Postfix`等服务的配置文件。

```bash
external_url 'https://git.xxx.top' # 这里填写你的域名
gitlab_rails['gitlab_shell_ssh_port'] = 18022 # 这里填写你自己映射的ssh端口
nginx['redirect_http_to_https'] = false # 是否将http重定向到https
nginx['ssl_certificate'] = "/etc/gitlab/xxx.top.pem" # 这里填写你的证书路径
nginx['ssl_certificate_key'] = "/etc/gitlab/xxx.top.key" # 这里填写你的证书路径
letsencrypt['enable'] = false # 关闭自动生成的证书
puma['worker_processes'] = 0 # 配置puma集群数量，减少内存占用
gitlab_rails['time_zone'] = 'Asia/Shanghai' # 配置时区
```

&ensp;&ensp;&ensp;&ensp;配置完成后，我们需要执行`gitlab-ctl reconfigure`命令，让`Gitlab`读取配置文件并生成配置文件。

&ensp;&ensp;&ensp;&ensp;但是为了方便，我们直接重新启动容器，重新启动也会让`Gitlab`读取配置文件。

```bash
docker restart gitlab
```

## 配置Nginx反向代理

```nginx
server {
        listen 80;
        server_name git.xxx.top;
        rewrite ^(.*)$ https://${server_name}$1 permanent;
}

server {
        listen 443 ssl;
        server_name git.xxx.top;
        ssl_certificate /srv/gitlab/config/xxx.top.pem;
        ssl_certificate_key /srv/gitlab/config/xxx.top.key;

        location / {
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto https;
                proxy_pass    https://127.0.0.1:18443; # 这里填写你的Gitlab容器的ip和端口
        }
}

```

&ensp;&ensp;&ensp;&ensp;配置完成后，我们需要执行`sudo nginx -s reload`命令，让`Nginx`重新加载配置文件。

&ensp;&ensp;&ensp;&ensp;如果每一步都配置正确，那么我们就可以通过`https://git.xxx.top`访问我们的`Gitlab`了。

&ensp;&ensp;&ensp;&ensp;如果你的`Gitlab`无法访问，可以查看容器的日志，找到错误原因。

```bash
 docker logs -f -t --tail=100 gitlab # 查看容器日志 只看最后100行 滚动查看
```

## 配置`Gitlab`初始化密码

&ensp;&ensp;&ensp;&ensp;我们可以通过`cat $GITLAB_HOME/config/initial_root_password`查看`Gitlab`的初始化密码。需要注意的是，这个文件会在24小时后失效。

&ensp;&ensp;&ensp;&ensp;我们需要通过这个密码，登录`Gitlab`后台，修改密码。

## 邮件配置

TODO...
