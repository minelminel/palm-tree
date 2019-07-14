# coding: utf-8
import os
import sys
import time
from flask import Flask, jsonify, request
from flask import render_template

app = Flask(__name__, template_folder='views')
tally = 0
start_time = time.time()

@app.route("/")
def hello_world():
    return render_template('base.html')

@app.route("/about")
def about():
    global tally, start_time
    tally += 1
    elapsed_time = time.strftime("%H:%M:%S", time.gmtime(time.time() - start_time))
    return render_template('about.html',  \
                            datetime=time.strftime("%d/%h/%Y %H:%M:%S"),  \
                            container=os.uname()[1],  \
                            elapsed_time=elapsed_time, \
                            syspath=sys.path, \
                            sysexec=sys.executable, \
                            tally=tally, \
                            environ=os.environ.__dict__, \
                            hosted=' '.join(os.uname()))

@app.route("/api",methods=["GET","POST"])
def api():
    args = request.args
    if request.method == "GET":
        return jsonify(message="hello world")

    elif request.method == "POST":
        return jsonify(**request.args)

    else:
        return jsonify(error="method not allowed")
