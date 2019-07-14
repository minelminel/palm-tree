# modifications for python36

```bash
yum -y remove mod_wsgi
pip install --upgrade pip setuptools
pip install mod_wsgi

WSGIPythonHome /usr/bin/python
WSGIPythonPath /usr/lib/python2.7/site-packages

<!-- WSGIPythonHome /usr/bin/python3.6
WSGIPythonPath /usr/lib/python3.6/site-packages/ -->

/setup/httpd-vhost-wsgi.conf
...
  Options +FollowSymLinks
  AllowOverride None
...



```

```yaml
FROM centos:7

LABEL maintainer 'Adriano Vieira <adriano.svieira at gmail.com>'

# install base packs
# apache.wsgi python pip
RUN yum -y install epel-release gcc; \
    yum -y install python-pip; \
    yum -y install python36 python36-pip python36-devel; \
    yum -y install httpd httpd-devel mod_wsgi; \
    yum clean all;

# Simple startup script to avoid some issues observed with container restart (CentOS tip)
COPY setup/run-apache-httpd.sh /run-apache-httpd.sh
RUN chmod -v +x /run-apache-httpd.sh

# setup apache default wsgi vhost
COPY setup/httpd-vhost-wsgi.conf /etc/httpd/conf.d/welcome.conf

# expose apache port
EXPOSE 80

# pip install app requirements
RUN pip install --upgrade pip setuptools && pip install --no-cache-dir virtualenv
COPY code/requirements.txt .
RUN pip install -r requirements.txt

# upload app to image
COPY code /var/www/html
WORKDIR /var/www/html

# run flask app on apache
CMD ["/run-apache-httpd.sh"]
```


```
# //////// system
[root@5eb389f5120f tmp]# python
Python 2.7.5 (default, Oct 30 2018, 23:45:53)
[GCC 4.8.5 20150623 (Red Hat 4.8.5-36)] on linux2
Type "help", "copyright", "credits" or "license" for more information.
>>> import sys
>>> sys.prefix
'/usr'
>>> sys.executable
'/usr/bin/python'
>>> sys.path
['', '/usr/lib64/python27.zip', '/usr/lib64/python2.7', '/usr/lib64/python2.7/plat-linux2', '/usr/lib64/python2.7/lib-tk', '/usr/lib64/python2.7/lib-old', '/usr/lib64/python2.7/lib-dynload', '/usr/lib64/python2.7/site-packages', '/usr/lib/python2.7/site-packages']
>>> exit()
[root@5eb389f5120f tmp]# cd ..
[root@5eb389f5120f /]# source env/bin/activate

# //////// venv
(env) [root@5eb389f5120f /]# python
Python 2.7.5 (default, Oct 30 2018, 23:45:53)
[GCC 4.8.5 20150623 (Red Hat 4.8.5-36)] on linux2
Type "help", "copyright", "credits" or "license" for more information.
>>> import sys
>>> sys.path
['', '/env/lib64/python27.zip', '/env/lib64/python2.7', '/env/lib64/python2.7/plat-linux2', '/env/lib64/python2.7/lib-tk', '/env/lib64/python2.7/lib-old', '/env/lib64/python2.7/lib-dynload', '/usr/lib64/python2.7', '/usr/lib/python2.7', '/env/lib/python2.7/site-packages']
>>> sys.executable
'/env/bin/python'
>>> sys.prefix
'/env'
>>>
```
