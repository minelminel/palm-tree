# -*- coding: UTF-8 -*-
import sys, os
from importlib import reload
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
reload(sys)


from main import app as application
