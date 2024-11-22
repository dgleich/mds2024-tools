import requests
from bs4 import BeautifulSoup,NavigableString, Tag
from urllib.parse import urljoin
import re


def extract_content_with_regex(html_content):
    pattern = re.compile(r'<h2>.*?</h2>(.*?)<dl>', re.DOTALL)
    match = pattern.search(html_content)
    if match:
        return match.group(1).strip()  # Returns the content between <h2> and <dl>
    else:
        return "Content not found."

def extract_ms_info(url):
    response = requests.get(url)
    content_between = extract_content_with_regex(response.text)
    return content_between

def crawl_mini_symposiums(base_url):
    response = requests.get(base_url)
    soup = BeautifulSoup(response.text, 'html.parser')
    ms_links = soup.find_all('a', string=lambda text: text and text.startswith(' MS'))

    ms_info = []
    for link in ms_links:
        full_url = urljoin(base_url, link.get('href'))
        ms_text = extract_ms_info(full_url)


        #print(f"Extracted info for {link.text}")
        #print(ms_text)
        ms_info.append({'title' :link.text, 'url': full_url, 'text' : ms_text} )

    # Save to a text file
    with open('mini_symposium_info.txt', 'w') as file:
        for info in ms_info:
            file.write("Title: " + info["title"] + '\n' + 
                       "URL: " + info["url"] + '\n' + 
                       info["text"] + '\n\n---\n\n')

base_url = 'https://meetings.siam.org/program.cfm?CONFCODE=mds24'
crawl_mini_symposiums(base_url)