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

# pip install app requirements
RUN pip3.6 install --upgrade pip setuptools && pip3.6 install --no-cache-dir virtualenv
RUN pip3.6 install mod_wsgi
COPY code/requirements.txt .
RUN pip3.6 install -r requirements.txt

# upload app to image
COPY code /var/www/html
WORKDIR /var/www/html

# allow httpd to work with python3
RUN mod_wsgi-express install-module > /etc/httpd/conf.modules.d/02-wsgi.conf

# run flask app on apache
CMD ["/run-apache-httpd.sh"]
