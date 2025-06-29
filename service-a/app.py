import os
import time
import requests
from threading import Thread
from flask import Flask
import logging

log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)

# --- Configuration from ENV ---
AVG_INTERVAL = int(os.getenv("AVG_INTERVAL", "10"))
API_URL = os.getenv("API_URL", "https://api.coinbase.com/v2/prices/BTC-USD/spot")
DATA_PATH = os.getenv("DATA_PATH", "data.amount").split(".")
HEALTH_FILE = "/tmp/healthy"
# -------------------------------

prices = []
minute = 0
app = Flask(__name__)

def extract_value(json_obj, path):
    """Safely extract nested value from JSON using a list of keys."""
    for key in path:
        if isinstance(json_obj, dict) and key in json_obj:
            json_obj = json_obj[key]
        else:
            return None
    return json_obj

def set_healthy():
    """Create or update health file to signal pod readiness."""
    with open(HEALTH_FILE, "w") as f:
        f.write("ok")

def set_unhealthy():
    """Remove health file to signal pod is unhealthy."""
    if os.path.exists(HEALTH_FILE):
        os.remove(HEALTH_FILE)

def get_bitcoin_price():
    """Fetch the current Bitcoin price from the API."""
    try:
        response = requests.get(API_URL, timeout=10)
        response.raise_for_status()
        price_str = extract_value(response.json(), DATA_PATH)
        return float(price_str) if price_str else None
    except Exception as e:
        print("Failed to get price:", e)
        return None

def run_worker():
    """Main background loop for fetching and printing prices."""
    global minute
    while True:
        price = get_bitcoin_price()
        if price is not None:
            prices.append(price)
            print(f"[Minute {minute}] Bitcoin price: ${price:.2f}")
            set_healthy()
        else:
            set_unhealthy()
            print(f"[Minute {minute}] Bitcoin price: unavailable")

        if minute > 0 and minute % AVG_INTERVAL == 0:
            if prices:
                avg = sum(prices) / len(prices)
                print(f"[Minute {minute}] {AVG_INTERVAL}-min average: ${avg:.2f}")
                prices.clear()

        minute += 1
        time.sleep(60)

@app.route("/")
def status():
    return "Service A is alive", 200

if __name__ == "__main__":
    # Run the background worker in a separate thread
    Thread(target=run_worker, daemon=True).start()
    # Start Flask server
    app.run(host="0.0.0.0", port=80)
