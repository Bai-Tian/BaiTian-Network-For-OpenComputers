# BaiTian-Network-For-OpenComputers
一个基于Minecraft opencomputers mod可以裸机运行的DNS服务器

## 客户端调用函数
function dns(d) component.modem.open(53) component.modem.broadcast(53,"dns",d) i=0 repeat i=i+1 a={event.pull(0.05,"modem")} until (a[1]=="modem_message" and (a[6]=="succeeded" or a[6]=="not found")) or i>3 return a[7],a[6] end  
  
用法：dns(要解析的域名) 返回：目标网卡地址，成功"succeeded"/失败"not found" 

提示：如果已知dns服务器网卡地址，以下代码中的broadcast可换成send
## API
客户端使用前不要忘记先打开53号端口接受信息 modem.open(53)  
1.解析域名：  
发送： modem.broadcast(53,"dns",要解析的域名)   
返回： 如果查询成功，第6个值为"succeeded"，第7个值为查询到的网卡地址。如果失败，则返回"not found"  
  
1.注册域名：  
发送： modem.broadcast(53,"dns_register",要注册的域名)   
返回： 如果注册成功，第6个值为"created"。如果已经用此网卡注册过，则返回"edited"。如果此网卡注册的域名已经被其他网卡注册过，则返回"failed"  

## 管理员命令
1.注册或强制修改域名：  
发送： modem.broadcast(53,"dns_register",要注册或强制修改的域名)   
返回： 如果修改成功，第6个值为"edited"  

2.返回所有注册过的域名：  
发送： modem.broadcast(53,"dns_list",要操作的域名后缀对应的服务器)  
返回： 如果查询成功，第6个值为一个包含所有域名和地址字符串  

3.设定开机字符串：  
发送： modem.broadcast(53,"dns_setawake",要操作的域名后缀对应的服务器,要设置的字符串)  
返回： 如果设置成功，第6个值为"setwakemessage"，失败为"setwakemessage failed"  

4.关机：  
发送： modem.broadcast(53,"dns_shutdown",要操作的域名后缀对应的服务器)  
返回： 如果操作成功，第6个值为"shutdown"  

## 架设须知
首先找一个空的管理模式的硬盘把init.lua导入进去  
代码第一行要先配置好 servername ：域名后缀，所有使用这个后缀的域名都由此服务器负责  
服务器启动后先用控制的电脑注册"CRTL.域名后缀"这个域名，以后此电脑就为服务器的管理员，可以执行管理员命令。注意架设后必须先注册好，否则被他人抢注后果自负。
