import sys
import os

# Add the current directory to sys.path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
# Add the parent directory (backend/) to sys.path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))

from main import app
from mangum import Mangum

# Wrap the FastAPI app with Mangum for Netlify Functions (AWS Lambda)
handler = Mangum(app, lifespan="off")
