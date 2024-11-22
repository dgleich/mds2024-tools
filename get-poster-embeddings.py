import os
from openai import OpenAI
import json
import re
import yaml 
import click 

# Load the API key from the environment variable
# openai.api_key = os.getenv("OPENAI_API_KEY")
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def get_embedding(text, model="text-embedding-3-large"):
  response = client.embeddings.create(
    input=[text],
    model=model
  )
  return response.data[0].embedding

data = yaml.load(open('posters-info.yaml', 'r'), Loader=yaml.FullLoader)
prevdata = yaml.load(open('posters-info-embeddings.yaml', 'r'), Loader=yaml.FullLoader)
for poster in data:
  # can we find the poster in the previous data?
  prevposter = next((item for item in prevdata if item['title'] == poster['title']), None)
  if prevposter and 'embedding' in prevposter:
    # if so, are the title and absract the same?
    if prevposter['title'] == poster['title'] and prevposter['abstract'] == poster['abstract']:
      # if so, copy the embedding
      poster['embedding'] = prevposter['embedding']
      continue 
  
  title = poster['title']
  abstract = poster['abstract']
  poster['embedding'] = get_embedding(title + " " + abstract)

yaml.dump(data, open('posters-info-embeddings.yaml', 'w'))  