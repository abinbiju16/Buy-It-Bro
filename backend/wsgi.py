import sys
import os

# Add the backend directory to sys.path
project_home = os.path.dirname(os.path.abspath(__file__))
if project_home not in sys.path:
    sys.path.insert(0, project_home)

from app.main import app
from a2wsgi import ASGIMiddleware

# PythonAnywhere looks for a variable called 'application'
application = ASGIMiddleware(app)
