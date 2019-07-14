FROM centos:7

LABEL maintainer 'Michael Lawrenson <michael.lawrenson@cubrc.org>'

# install base packs
# apache.wsgi python pip
RUN yum -y install epel-release gcc tree; \
    yum -y install python36 python36-pip python36-devel; \
    yum -y install httpd httpd-devel; \
    yum clean all;

# Simple startup script to avoid some issues observed with container restart (CentOS tip)
COPY setup/run-apache-httpd.sh /run-apache-httpd.sh
RUN chmod -v +x /run-apache-httpd.sh

# setup apache default wsgi vhost
COPY setup/httpd-vhost-wsgi.conf /etc/httpd/conf.d/welcome.conf

# expose apache port
EXPOSE 80

# pip install app requirements, virtualenv
RUN pip3.6 install --upgrade pip setuptools && pip3.6 install --no-cache-dir virtualenv
RUN virtualenv -p python3 /usr/local/env && source /usr/local/env/bin/activate
RUN pip3.6 install mod_wsgi

# allows httpd to work with python3
RUN mod_wsgi-express install-module > /etc/httpd/conf.modules.d/02-wsgi.conf

# create file for use as flask log
RUN touch /var/log/httpd/flask_log

# this portion will be replaced by the below "install main repo package"
COPY code/requirements.txt .
RUN pip3.6 install -r requirements.txt

# upload app to image
COPY code /var/www/html
WORKDIR /var/www/html

# install the main repo package
# RUN pip3.6 install -e .

# run flask app on apache
CMD ["/run-apache-httpd.sh"]
