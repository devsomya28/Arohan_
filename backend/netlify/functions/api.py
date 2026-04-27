import sys
import os

# Add the parent directory to sys.path so we can import the 'app' module
# This is necessary for Netlify Functions to find your FastAPI code
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from main import app
from mangum import Mangum

# Wrap the FastAPI app with Mangum for Netlify Functions (AWS Lambda)
handler = Mangum(app, lifespan="off")
