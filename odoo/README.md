stack_name -> .Release.Name
servername;name->fullname
namespace 传入与stack_name相同值，达到stack_name与namespace相同的效果

for example:
helm template cms-1234 --namespace cms-1234 --set image.agent.repository=odooagentcitest,image.agent.tag=0.0.20,fullnameOverride=cms-1234-cms mylibrary/odoo

通过template生产部署yaml文件,再调用kube接口进行部署,
mylibrary/odoo 为在https://registry.cloudclusters.net中的chart模板,需先通过helm repo add mylibrary               https://registry.cloudclusters.net/chartrepo/chart_test 添加进节点中

--set 为此次构建传入自定义的值 如镜像版本,需要的环境变量,此处部署的完整名字,plan规格
-f 也可通过此flag,将此次自定义值通过文件传入,文件中定义的值会覆盖默认value.yaml中的值

helm客户端=>kube_translator.py
mylibrary/odoo=>对应模板文件
--set -f =>现有的传值


 WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.

 在/etc/sysctl.conf中添加如下

net.core.somaxconn = 2048

然后在终端中执行

sysctl -p
