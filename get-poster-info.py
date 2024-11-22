import requests
from bs4 import BeautifulSoup
import yaml
import click
import re

def get_abstract(talk_id):
  url = f'https://meetings.siam.org/sess/dsp_talk.cfm?p={talk_id}'
  response = requests.get(url)
  soup = BeautifulSoup(response.text, 'html.parser')

  # Extract the title
  title_div = soup.find('div', class_='ptitle')
  title = title_div.get_text(strip=True) if title_div else None

  # Extract the abstract
  abstract_div = soup.find('div', class_='abstract')
  if abstract_div:
    # Remove the word "Abstract." and any HTML tags
    abstract_text = ' '.join(abstract_div.stripped_strings).replace('Abstract.', '').strip()
  else:
    abstract_text = 'Abstract not found'

  return {'title': title, 'abstract': abstract_text}

  

@click.command()
@click.option('--url', default='https://meetings.siam.org/participant.cfm?CONFCODE=mds24', help='URL of the page to crawl')
@click.option('--output', default='posters-info.yaml', help='Output YAML file')
#@click.option('--abstracts', default='poster-abstracts.tex', help='Output LaTeX file from SIAM poster abstract dump process')
def crawl(url, output):
  # Report command line arguments
  click.secho(f"Command line arguments:", fg='blue')
  click.secho(f"  URL: {url}", fg='blue')
  click.secho(f"  Output: {output}", fg='blue')

  response = requests.get(url)
  if response.status_code != 200:
    click.secho(f"Error: Failed to retrieve the url '{url}'. Status code: {response.status_code}", fg='red', bold=True)
    return

  soup = BeautifulSoup(response.text, 'html.parser')
  entries = soup.find_all('dt')

  posters = []

  abstracts_used = set()

  soup = BeautifulSoup(response.text, 'html.parser')
  elements = soup.find_all(['dt', 'dd'])

  presenter = None
  email = None

  for element in elements:
    if element.name == 'dt':
      presenter_tag = element.find('b')
      presenter = presenter_tag.get_text(strip=True).rstrip(':')
      email = presenter_tag.next_sibling.strip()
      #print(f"Presenter: {presenter}, Email: {email}")
    elif element.name == 'dd' and element.find('a'):
      link = element.find('a')
      papernumber = int(link['href'].split('PAPERNUMBER=')[1].split('&')[0])
      title = link.get_text(strip=True)

      abstract_info = get_abstract(papernumber)

      if abstract_info['title'] == 'Title not found' or abstract_info['abstract'] == 'Abstract not found':
        click.secho(f"Warning: No abstract found for poster {papernumber}.", fg='yellow', bold=True)
      abstract = abstract_info['abstract']

      poster = {
        'poster': papernumber,
        'presenter': presenter,
        'email': email,
        'title': title,
        'abstract': abstract,
      }
      posters.append(poster)

  with open(output, 'w') as file:
    yaml.dump(posters, file, sort_keys=False)

  click.secho(f"Successfully wrote poster information for {len(posters)} posters to {output}", fg='green', bold=True)


if __name__ == '__main__':
  crawl()
