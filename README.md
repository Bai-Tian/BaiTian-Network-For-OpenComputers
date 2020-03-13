# BaiTian-Network-For-OpenComputers
一个基于Minecraft opencomputers mod可以裸机运行的DNS服务器

## 说明
代码的前三行需要先配置好：  
ctrl ：控制端的网卡地址，服务器产生的消息会发给这个地址，也只有来自这个地址的设备才能控制服务器  
servername ：域名后缀，所有使用这个后缀的域名都由此服务器负责  
swm ：服务器开机唤醒字符串，默认为BaitianNetworkServer..域名后缀  
客户端使用前不要忘记先打开53号端口接受信息 modem.open(53)  
\
## API
1.解析域名：  
发送： modem.broadcast(53,"dns",要解析的域名)   
返回： 如果查询成功，第6个值为"succeeded"，第7个值为查询到的网卡地址。如果失败，则返回"not found"  
  
1.注册域名：  
发送： modem.broadcast(53,"dns_register",要注册的域名)   
返回： 如果注册成功，第6个值为"created"。如果已经用此网卡注册过，则返回"edited"。如果此网卡注册的域名已经被其他网卡注册过，则返回"failed"  
