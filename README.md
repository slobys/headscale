# 使用说明<br />
本脚本适用于国内安装，因此需要提前下载好对应的文件<br />
## 具体需要下载的文件如下：<br />
go下载：https://go.dev/dl/  
headscale下载：https://github.com/juanfont/headscale/releases  
headscale-ui下载：https://github.com/gurucomputing/headscale-ui/releases  
文件下载好之后，上传到服务器的/root目录下  
这里有两个脚本，需要分别执行命令  
1、一键搭建Derp服务器需要用以下命令      
```bash
chmod +x tailscale.sh && ./tailscale.sh
```
2、一键搭建Headscale和Headscale-ui需要用以下命令
```bash
chmod +x headscale.sh && ./headscale.sh
```
