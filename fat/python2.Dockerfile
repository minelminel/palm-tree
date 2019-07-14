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
