# BaiTian-Network-For-OpenComputers
一个基于Minecraft opencomputers mod的网络系统  

## 客户端函数库使用方法：  
1.下载baitian_modem.lua放进lib文件夹内  
2.下载SERVERSADDR.lua放进根目录内  
3.在代码里require("baitian_modem")或者在运行代码前运行一遍baitian_modem.lua  

## 新增的函数： 
1.baitian_modem.dns(域名)  
返回：如果连接上服务器，第一个值为"succeeded"，第二个值为查询到的地址，或者第一个值为"not found"，第二个值为nil  
如果在本次开机后已经查询过同样的域名，则第一个值为"from the cache"，第二个值为查询到的地址  
如果网络连接出现错误，则第一个值为"connection failed"，第二个值为nil  

2.baitian_modem.dnsp(域名)  
和上一个函数一个功能，只不过这个函数每次执行都会连接DNS服务器，不会从缓存中查找  

3.baitian_modem.dns_register(域名)  
返回： 如果注册成功，第6个值为"created"。如果已经用此网卡注册过，则返回"edited"。如果此网卡注册的域名已经被其他网卡注册过，则返回"failed"  
如果网络连接出现错误，则返回值为nil  

## 修改原有的函数：
发送：  
component.modem.broadcast()  
component.modem.send()  
接收：  
event.listen()  
event.pull()  
使用方法和原版相同，不过上面所有的函数都是用来支持中继服务器存在的。  
如果不想使用中继服务器，请在函数名前加"old."，例如"old.component.modem.broadcast"使用原来函数的功能。  
