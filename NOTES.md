# modifications for python36

The most important considerations are that the version of mod_wsgi matches the python3 version,
and that the virtual environment is called upon script execution.

We install virtualenv globally, and all requirements within in.
We source the `activate` file before installing mod_wsgi and setup.py as to ensure inclusion in the syspath.

Within the httpd .conf we must specify the location of our virtualenv. We use a system-level location to standardize the file path.

We also pipe the auto-generated text snippet allowing mod_wsgi to talk to python into a location monitored by httpd.conf
