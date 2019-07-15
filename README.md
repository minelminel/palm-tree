# CentOS 7 + Apache HTTPD + Flask -- Deployment Guide

![Screen Shot 2019-07-14 at 11 38 59 PM](https://user-images.githubusercontent.com/46664545/61194622-ac6f7d80-a690-11e9-87df-f39e320ec291.png)

###### `about` page of the sample app

We will install a Flask service within a CentOS 7 instance, with Apache HTTPD as our server. For those unaccustomed to working with Python in a production environment, some background: Python requires a middleman to translate http requests into executable Python instructions, and to execute such instructions in a threaded manner. The built-in server that comes with Flask is great for development as it allows live source code reloading, simple startup, and friendly error tracebacks which allow arbitrary command execution within the stack. It should be known, though, that this native server is NOT designed for production use, as it is single-threaded and implements no permission control. Apache HTTPD acts as our web gateway in the same way you're accustomed to, and a module called `mod_wsgi` handles our Python execution. **Important: make sure you do NOT install mod_wsgi as a yum package, as we must ensure that the version of mod_wsgi is compiled for our specific Python version. Rather, we will install mod_wsgi directly into our virtualenv. Make sure to include the gcc yum package as mod_wsgi must be compiled upon installation.**

## Modifications for Python36

The most important considerations are that:
- the version of mod_wsgi matches the python3 version, and
- the virtual environment is called upon script execution

We install virtualenv globally, and all requirements within in.
We source the `activate` file before installing mod_wsgi and setup.py as to ensure accessiblity from the PATH.

Within the httpd .conf we must specify the location of our virtualenv. We use a system-level location `/usr/local/env` to standardize the file path, and to ensure no permission conflicts.

We also pipe an auto-generated text snippet allowing mod_wsgi to talk to python into a location monitored by httpd.conf

If using a Dockerfile for our build process, there is a minor difference between installing dependencies through a requirements.txt file, or through setup.py

If we are using a setup.py method of installation, we will want to wait until we have copied our source code into the WORKDIR,
so that the resulting egginfo file will reside in a place that is accessible within our PATH.
In the case of requirements.txt, we can either copy the requirements file from the repo to a top-level directory and read it from there, or provide the full file path to the requirements file within the repo. Since pip-installed packages are automatically installed into a path-accessible location and leave no local artifacts, we may either run our installation command before or after declaring the WORKDIR.

## VM Manual Installation -- Overview
Important Locations

| Asset    | Path    |
| :------------- | :------------- |
| Source Code       | /var/www/html/       |
| HTTPD configuration       | /etc/httpd/conf.d/       |
| WSGI configuration       | /etc/httpd/conf.d.modules/       |
| Flask log       | /var/httpd/log/flask_log       |
| virtualenv       | /usr/local/env/      |
| HTTPD startup script       | /      |


We assume that you're working with a fresh install of CentoOS 7, however, the procedures will be similar for other linux flavors.

[1] Install System Prerequisites
```bash
yum -y update
yum -y install epel-release gcc tree
yum -y install python36 python36-pip python36-devel
yum -y install httpd httpd-devel
yum clean all
```

[2] Copy our virtualhost configuration to a location monitored by HTTPD. A sample file is shown below, as well as the location which we should move it to. Note that we assume the presence of our wsgi file in the top-level of our repo, and that the file uses the name `app.wsgi`. The wsgi file is nothing more than a Python script that provides an entrypoint to our application, and uses the `.wsgi` extension only as a convention. A sample `app.wsgi` file is shown in step 8.
```
# wsgi log level verbose: info
LogLevel warn

<VirtualHost *:80>
  ServerName  localhost
  ServerAlias localhost
  DocumentRoot /var/www/html/

  WSGIDaemonProcess webhook user=apache group=apache threads=5
  WSGIScriptAlias / /var/www/html/app.wsgi

  # application reload = On
  WSGIScriptReloading Off

  <Directory /var/www/html>
      WSGIProcessGroup webhook
      WSGIApplicationGroup %{GLOBAL}
      Order deny,allow
      Allow from all
  </Directory>
</VirtualHost>
```
Location to write our conf file to
```bash
# override the default Apache welcome page to use our application
/etc/httpd/conf.d/welcome.conf
```
If working from the provided boilerplate, use the following command
```bash
# override the default Apache welcome page to use our application
cp setup/httpd-vhost-wsgi.conf /etc/httpd/conf.d/welcome.conf
```

[3] CentoOS + HTTPD can exhibit a weird bug when restarting the service, use the provided script to mitigate this behavior. We will use this command to start our service once our installation is complete.
```
#!/bin/bash

# Make sure we're not confused by old, incompletely-shutdown apache/httpd
# context after restarting the container.  apache/httpd won't start correctly
# if it thinks it is already running.
rm -rf /run/httpd/* /tmp/httpd*

exec /usr/sbin/apachectl -DFOREGROUND
```
If working from the provided boilerplate, you can run this command to add it to the root of your filesystem. Make sure to allow the file to be run as an executable.
```bash
cp setup/run-apache-httpd.sh /run-apache-httpd.sh
chmod +x /run-apache-httpd.sh
```

[4] Install Python-related packages. The only system-wide installation we will perform is virtualenv, as this allows us to structure our other package installations in a reproducible and contained environment.
```bash
pip3.6 install --upgrade pip setuptools
pip3.6 install virtualenv
```
Create and activate our virtualenv
```bash
virtualenv -p python3 /usr/local/env
source /usr/local/env/bin/activate
```

Install mod_wsgi
```bash
# make sure that virtualenv is activated before proceeding
pip3.6 install mod_wsgi
# allow httpd to communicate with Python3
mod-wsgi-express install-module > /etc/httpd/conf.modules.d/02-wsgi.conf
```

Install app packages + requirements
```bash
# requirements.txt
pip3.6 install -r requirements.txt

# setup.py
python3 setup.py install
# OR,
pip3.6 install -e .
```
NOTE: if installing packages through a `setup.py` script, it is recommended to perform this action AFTER copying your source code to the expected file location.

[6] Create dedicated Flask log file (recommended)
```bash
touch /var/log/httpd/flask_log
```

[7] Move your source code to the expected location. You may either directly load your source code into the expected location (recommended for simple applications), or store your code in a temporary location moving only the minimum necessary files to the expected location (recommended)
```bash
mv /path/to/repo /var/www/html/
```
NOTE: if using a `setup.py` script to run your installation, perform that operation now.

[8] Create your app.wsgi script within `/var/www/html`. Please note the expected convention of importing your service as application. A sample script is provided below
```python
# -*- coding: UTF-8 -*-
import sys, os
from importlib import reload
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
reload(sys)

from main import app as application
```

[9] Start the service using the `run-apache-httpd.sh` script we created previously
```bash
cd /
./run-apache-httpd.sh
```

If everything is working properly, your service should now be accessible. If the server returns a `500 - Internal Server Error`, check the log to see what's causing the problem.
```bash
# httpd error log
cat /var/log/httpd/error_log
# flask error log (assuming this has been configured within your app)
cat /var/log/httpd/flask_log
```
You can view *only* the last segment of either log by replacing the `cat` command with `tail`

If you run into issues while following this guide, try running the provided Dockerfile along with the boilerplate repo to identify discrepancies, as the Dockerfile can be considered 100% functional.
<!--  -->
