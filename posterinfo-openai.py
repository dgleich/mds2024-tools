# Set your OpenAI API key
from openai import OpenAI

import os
import re
import json


client = OpenAI(
    # This is the default and can be omitted
    api_key=os.environ.get("OPENAI_API_KEY"),
)

# Function to extract and format posters information
def extract_posters(record):
  posters_pattern = re.compile(r'(Associated poster:|Poster #[0-9]+:)\s*(.*?)\s*<P>', re.DOTALL)
  posters = posters_pattern.findall(record)
  return [poster[1].strip() for poster in posters]

# Function to generate the OpenAI messages
def generate_messages(text):
  system_message = {
    "role": "system",
    "content": "You are a helpful assistant that extracts poster information from text and formats it into a JSON array with objects containing 'title', 'people' (optional), and 'email' (optional). The poster information is usually before the organizers section of the associated text. Only report email if it's a valid email address. There will be multiple posters to find.  Give raw JSON output"
  }
  
  user_message = {
    "role": "user",
    "content": text 
  }
  
  return [system_message, user_message]

# Function to send request to OpenAI and get the response
def get_openai_response(messages):
  response = client.chat.completions.create(
    model="gpt-4o",
    messages=messages,
    temperature=1,
    max_tokens=1577,
    top_p=1,
    frequency_penalty=0,
    presence_penalty=0,
    response_format={ "type": "json_object" },
  )
  return response.choices[0].message.content

# Function to process a single record
def process_record(record):
  url_pattern = re.compile(r'URL: (.*?)\s*<p>', re.DOTALL)
  url_match = url_pattern.search(record)
  if not url_match:
    return None
  
  url = url_match.group(1).strip()
  messages = generate_messages(record)
  openai_response = get_openai_response(messages)
  print("Processed record for URL:", url)
  print("Record:", record)
  print("OpenAI Response:", openai_response)
  print()
  print() 
  print() 
  return { "url": url, "posters": json.loads(openai_response) }

# Read records from file
with open('mini_symposium_info.txt', 'r') as file:
  records = file.read().split("\n---\n")

# Process each record and save the results
results = []
for record in records:
  result = process_record(record)
  if result:
    results.append(result)
  
# Save the results to a JSON file
with open('processed_minisymposium_records.json', 'w') as file:
  json.dump(results, file, indent=2)

print("Processing complete. Results saved to processed_minisymposium_records.json.")
