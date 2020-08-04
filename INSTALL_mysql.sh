#!/bin/sh
# Author��anbingyu
# function: ����mysql�ٷ�yumԴ���Զ���װmysql����������
# apply: centos 7.5


function install_before {
    #��־���
    if [[ ! -e /tmp/an_shell_log ]]; then
        touch /tmp/install_mysql_log 
    fi
    #��װmysql yumԴ�İ汾���ƹ��ߺͳ������
    yum -y install wget
    if [[ $(rpm -qa | grep yum-utils | wc -l) -eq 0 ]];then 
        yum -y install yum-utils 
        if [[ $? -ne 0 ]]
            echo "����yumԴ��δ�ɹ���װyum������"
            exit 0
        fi
    fi
    #���mysql�Ƿ�װ��Դ��ɾ��
    if [[ $(rpm -qa | grep mysql80-community | wc -l) -ne 0 ]];then 
        rpm -e mysql80-community 
    fi
}

function setaliyunrepos {
    
    #����ԭ��repo����
    mkdir /etc/yum.repos.d/backrepo
    cp /etc/yum.repos.d/* /etc/yum.repos.d/backrepo
    rm -rf /etc/yum.repos.d/*.repo
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo 
    # �ǰ������豸��Ҫʹ������һ�����
    sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo 
    
    yum clean all 
    yum makecache 
    if [ `yum repolist |grep mirrors.aliyun.com | wc -l` -ge 1 ] ;then
        echo "aliyunrepos complete "
    else
        echo "aliyunrepos error"
}

function install_mysql {
    wget https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm 
    rpm -ivh  mysql80-community-release-el7-3.noarch.rpm 
    rm -rf mysql80-community-release-el7-3.noarch.rpm 
    echo "mysql yumrepo  complete"
    read -p "plase input install version 1: mysql80 2: mysql57   
    " banben

    if [[ $banben -eq 2 ]];then
        yum-config-manager --disable mysql80-community
        yum-config-manager --enable mysql57-community
            if [[ $? -ne 0 ]]
                echo "����yum������,δ���óɹ�5.7�汾"
                exit 0
            fi
    fi
    
    echo "mysql install start"
    if [[ $(rpm -qa |grep mysql | wc -l) -gt 4 ]];then 
        yum -y reinstall mysql mysql-server 
    else
        yum -y install mysql mysql-server
    fi

    echo "mysql install complete"
    }

function mimachushihua {
    #mysql ��ʼ����
    echo '[mysqld]
    datadir=/var/lib/mysql
    socket=/var/lib/mysql/mysql.sock
    # Disabling symbolic-links is recommended to prevent assorted security risks
    symbolic-links=0
    # Settings user and group are ignored when systemd is used.
    # If you need to run mysqld under a different user or group,
    # customize your systemd unit file for mariadb according to the
    # instructions in http://fedoraproject.org/wiki/Systemd
    #����Ȩ�޹���
    skip_grant_tables

    [mysqld_safe]
    log-error=/var/log/mariadb/mariadb.log
    pid-file=/var/run/mariadb/mariadb.pid


    ' > /etc/my.cnf
    systemctl enable mysqld --now
    mysql -u root<<EOF
    use mysql;
    update user set authentication_string=password('Newpass12__') where user='root'; 
    flush privileges;
EOF
    sed -i "s/skip_grant_tables//g" /etc/my.cnf 
    systemctl restart mysqld 

    mysql -u root -pNewpass12__  --connect-expired-password <<EOF
    set global validate_password_policy=LOW;
    set global validate_password_length=6;
    ALTER USER 'root'@'localhost' IDENTIFIED BY '123456';
    ALTER USER 'root' IDENTIFIED BY '123456';
EOF

    echo "mima change successful"
    echo "mima is :123456"
    }
}

function zhucongfuzhi {
    #������ǽ�Ƿ�ͨ3306
    #���ӷ��������ݿ��Ƿ����root�˻�Ȩ��
    #������������
    server-id = 1
    log_bin = master-a-bin 
    binlog-format=ROW
    grant replication slave on *.* to 'root'@'192.168.126.*' identified by '123456';
    #���ôӷ�����
    server-id = 2
    log_bin = master-a-bin 
    binlog-format=ROW
    #log-slave-updates=true   #�ӷ���������������һ̨����������
    change master to master_host='192.168.210.133',master_port=3306,master_user='root',master_password='123456',master_log_file='master-a-bin.000003',master_log_pos=154;
    #��������ͬ��
    start slave;
    stop slave;
    show slave status\G;
}
function duxiefenli {
    #��д�����м��
    #1��mycat 2:Atlas 3:proxysql
    
}


#������绷��
if [[ `ping -c 5 mirrors.aliyun.com |grep from |wc -l` -le 4 ]];then
    echo "������ϣ�����"
    exit 0
fi

#����û��Ƿ�rootȨ��
if [[ `id |grep -v uid=0 | wc -l` -eq 1 ]];then
    echo "Ȩ�޷�root"
    exit
fi






setaliyunrepos
install_before
install_mysql
mimachushihua
