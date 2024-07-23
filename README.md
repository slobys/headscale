# 使用说明  
本脚本适用于国内安装，因此需要提前下载好对应的文件  
## 具体需要下载的文件如下：    
[go下载](https://go.dev/dl/)  
[headscale下载](https://github.com/juanfont/headscale/releases/tag/v0.22.3) **注意：请下载稳定版v0.22.3，目前测试新版有问题**  
[headscale-ui下载](https://github.com/gurucomputing/headscale-ui/releases)  
文件下载好之后，上传到服务器的/root目录下  

## 下载好文件并上传到/root目录之后，执行以下命令  
1、安装git  
```
sudo apt install git -y
```
2、下载一键脚本并把脚本放到/root目录下
```
git clone https://github.com/slobys/headscale.git && sudo mv headscale/* /root/

```
3、一键搭建Derp服务器需要用以下命令      
```
chmod +x tailscale.sh && ./tailscale.sh
```
4、一键搭建Headscale和Headscale-ui需要用以下命令
```
chmod +x headscale.sh && ./headscale.sh
```
