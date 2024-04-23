import os
from dotenv import load_dotenv
import requests
import json


load_dotenv()

API_KEY = os.getenv('API_KEY')
CONTRACT_ADDRESS = os.getenv("CONTRACT_ADDRESS")
USDT_ADDRESS = os.getenv("USDT_ADDRESS")
USDC_ADDRESS = os.getenv("USDC_ADDRESS")

TRANSACTION_URL = "https://api.etherscan.io/api?module=account&action=txlist&address="+CONTRACT_ADDRESS+"&startblock=0&endblock=99999999&sort=asc&apikey"+API_KEY
USDT_USDC_TOKEN_URLS = [
    "https://api.etherscan.io/api?module=account&action=tokentx&contractaddress="+USDT_ADDRESS+"&address="+CONTRACT_ADDRESS+"&sort=asc&apikey="+API_KEY,
    "https://api.etherscan.io/api?module=account&action=tokentx&contractaddress="+USDC_ADDRESS+"&address="+CONTRACT_ADDRESS+"&sort=asc&apikey="+API_KEY
]

tokenIds=[]
buyers=[]
prices=[]
levels=[]


def price_to_level(prices):
    with open("levelPrices.json") as price_config_file:
        level_config = json.load(price_config_file)

    for price in prices:    
        for level_data in level_config:
            if(price == level_data.get("price")):
                levels.append(level_data.get("level"))
                break

def write_to_json(tokenIds, buyers, levels):
    # Forming dictionary for writing
    formed_dictionary_list=[]
    for i, id in enumerate(tokenIds):
        formed_dictionary = {
            "token_id": id,
            "wallet": buyers[i],
            "level": levels[i]
        }
        formed_dictionary_list.append(formed_dictionary)
        
    # Serializing json
    json_object = json.dumps(formed_dictionary_list, indent=2)
    
    # Writing to file
    with open("nftData.json", "w") as outfile:
        outfile.write(json_object)
    

def scrape_buyers(transaction_url, usd_token_urls):
    transaction_response = requests.get(transaction_url)
    transaction_list = transaction_response.json()

    id = 0
    for function in transaction_list["result"]:
        if(function["functionName"] == "mintNft(uint16 level,address token)"):
            buyers.append(function["from"])
            for token_url in usd_token_urls:
                usd_response = requests.get(token_url)
                usd_transaction_list = usd_response.json()
                for usd_transaction in usd_transaction_list["result"]:
                    if(function["hash"] == usd_transaction["hash"]):
                        prices.append(usd_transaction["value"])
                        break
            tokenIds.append(id)
            id+=1
            


scrape_buyers(TRANSACTION_URL, USDT_USDC_TOKEN_URLS)
price_to_level(prices)
write_to_json(tokenIds, buyers, levels)