import os
from openai import OpenAI
import json
import re

# Load the API key from the environment variable
# openai.api_key = os.getenv("OPENAI_API_KEY")
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))


# Read the data from the file
def read_data(file_path):
  with open(file_path, 'r') as file:
    content = file.read()
  entries = content.split('---\n')
  data = []
  for entry in entries:
    lines = entry.strip().split('\n')
    if len(lines) < 3:
      print(f"Skipping entry: {lines}")
      continue
    title = lines[0].replace('Title:  ', '')
    url = lines[1].replace('URL: ', '')
    text = '\n'.join(lines[3:])
    text = remove_html_tags(text)
    text = remove_organizer_section(text)
    text = remove_associated_poster(text)
    data.append({
      'title': title,
      'url': url,
      'text': text
    })
  return data

def remove_html_tags(text):
  clean = re.compile('<.*?>')
  return re.sub(clean, '', text)

def remove_associated_poster(text):
  text = re.sub(r'Associated Poster:\s*', '', text, flags=re.IGNORECASE)
  text = re.sub(r'Associated Posters:\s*', '', text, flags=re.IGNORECASE)
  text = re.sub(r'Associated Posters\s*', '', text, flags=re.IGNORECASE)
  text = re.sub(r'Associated Poster\s*', '', text, flags=re.IGNORECASE)
  return text 
  
  


# Function to remove everything from "Organizer:" to the end
def remove_organizer_section(text):
  organizer_index = text.find('Organizer:')
  if organizer_index != -1:
    return text[:organizer_index].strip()
  return text.strip()

def get_embedding(text, model="text-embedding-3-large"):
  response = client.embeddings.create(
    input=[text],
    model=model
  )
  return response.data[0].embedding

data = read_data('mini_symposium_info.txt')

# List to hold the results
results = []

for item in data:
  title_embedding = get_embedding(item["title"])
  text_embedding = get_embedding(item["text"])

  results.append({
    "title": item["title"],
    "url": item["url"],
    "title_embedding": title_embedding,
    "text_embedding": text_embedding
  })

# Save the results to a JSON file
with open('mini-embeddings.json', 'w') as f:
  json.dump(results, f)

print("Embeddings have been saved to mini-embeddings.json")
