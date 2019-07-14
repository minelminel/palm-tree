# coding: utf-8
'''
Application: flask
Modulue: main
description: Tasting docker, redis, kafka
author: Adriano dos Santos Vieira <adriano.svieira at google.com>
character encoding: UTF-8
'''
import os, time
import sys
from flask import Flask
from flask import render_template

application = Flask(__name__, template_folder='views')
tally = 0

@application.route("/")
def hello_world():
    return render_template('base.html')

@application.route("/about")
def about():
    global tally
    tally += 1
    return render_template('about.html',  \
                            datetime=time.strftime("%d/%h/%Y %H:%M:%S"),  \
                            container=os.uname()[1],  \
                            syspath=sys.path, \
                            sysexec=sys.executable, \
                            tally=tally, \
                            hosted=' '.join(os.uname()))
