#!/bin/bash
## author: limaochao
## date: 2022-01-14
## usage: baseline

# 最小密码长度
sed -i 's/PASS_MIN_LEN	5/PASS_MIN_LEN    8/g' /etc/login.defs

# 密码复杂度，dcredit数字字符个数，ucredit大写字符个数，ocredit特殊字符个数，lcredit小写字符个数
sed -i '/pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=/s/$/ minlen=9 dcredit=-1 ucredit=-1 lcredit=-1/g' /etc/pam.d/system-auth

# 密码过期时间
sed -i 's/PASS_MAX_DAYS	99999/PASS_MAX_DAYS	180/' /etc/login.defs

# 密码最短使用期限
sed -i 's/PASS_MIN_DAYS	0/PASS_MIN_DAYS	2/' /etc/login.defs

# 添加管理员用户（组）
groupadd admin -g 2222
useradd admin -p 2222 -g 2222
echo "Ning12#$" | passwd --stdin admin

# 禁止root远程登录ssh
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd 

# 登录失败锁定
sed -i '/auth        required      pam_deny.so/a auth        required        pam_tally2.so deny=5 unlock_time=600 no_lock_time/' /etc/pam.d/system-auth
sed -i '/auth       include      postlogin/a auth        required        pam_tally2.so deny=5 unlock_time=600 no_lock_time' /etc/pam.d/sshd
sed -i '/account    include      password-auth/a account    required    pam_tally2.so' /etc/pam.d/sshd

# 口令重复使用次数
# echo -e 'Auth required pam_stack.so service=system-auth
# Account required pam_stack.so service=system-auth
# Password requisite pam_unix.so remember=3
# Password requisite pam_passwdqc.so enforce=everyone' >> /etc/pam.d/passwd
sed -i '/password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok/s/$/ remember=5/g' /etc/pam.d/system-auth

# 限制普通用户su
sed -i '/auth		include		postlogin/a auth		required		pam_wheel.so group=admin' /etc/pam.d/su
sed -i '/auth		include		postlogin/a auth		sufficient		pam_rootok.so' /etc/pam.d/su

# 远程日志管理
echo '*.* @10.190.8.49:514' >> /etc/rsyslog.conf
/usr/bin/systemctl restart rsyslog

# 时间同步
# sed -i 's/server 3.centos.pool.ntp.org iburst/a\ server/' /etc/chrony.conf

# 禁止ICMP重定向
/usr/bin/echo 'net.ipv4.conf.all.accept_redirects=0' >> /etc/sysctl.conf && /usr/sbin/sysctl -p 

# 设置登录超时
/usr/bin/echo 'export TMOUT=300' >> /etc/profile && source /etc/profile

# 禁止非必要服务启动
systemctl stop postfix && systemctl disable postfix 

# 设置ssh登录banner
/usr/bin/touch /etc/ssh_banner && chown bin:bin /etc/ssh_banner && chmod 644 /etc/ssh_banner && /usr/bin/echo 'Authorized only. All activity will be monitored and reported' > /etc/ssh_banner && /usr/bin/echo 'Banner /etc/ssh_banner' >> /etc/ssh/sshd_config
systemctl restart sshd