import csv
import json
import yaml
from thefuzz import fuzz, process
import click 
from rich.console import Console
import os 
from typing import List, Dict, Any

"""
MIT License

Copyright (c) 2024 David F. Gleich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

console = Console()
DEBUG = False
DEFAULT_THRESHOLD = 80
# 2024-06-06: Note you will match 'Yuntian Chen' and 'Yifan Chen' at name threshold 80, so we upped this to 85. 
DEFAULT_NAME_THRESHOLD = 85

def debug_print(msg, fg="white", debugheader="DEBUG: "):
  global DEBUG
  if DEBUG:
    click.echo(click.style(debugheader + msg, fg=fg))

def warning(msg, fg="yellow", header="Warning: "):
  click.echo(click.style(header + msg, fg=fg))

# Function to save results as YAML
def save_as_yaml(data, file_path):
  with open(file_path, 'w', encoding='utf-8') as file:
    yaml.dump(data, file, allow_unicode=True)

# Read from a yaml file into a dictionary
def read_yaml(file_path):
  with open(file_path, 'r', encoding='utf-8') as file:
    return yaml.safe_load(file)

# Function to read and parse the JSON file
def read_json(file_path):
  with open(file_path, 'r', encoding='utf-8') as file:
    data = json.load(file)
  return data  

# Function to read and parse the CSV file
def read_posters_csv(file_path):
  posters = []
  with open(file_path, mode='r', newline='', encoding='utf-8') as csvfile:
    # Skip the first two rows
    next(csvfile)
    next(csvfile)
    reader = csv.DictReader(csvfile)
    for row in reader:
      if 'ID#' in row and row['ID#']:
        posters.append({
          'id': int(row['ID#']),
          'last_name': row['Last Name'],
          'first_name': row['First Name'],
          'email': row['Email'].strip(),
          'title': row['Title']
        })
  if DEBUG:
    debug_print(f"Read {len(posters)} posters from CSV file",)
    # print a list of posters
    for poster in posters:
      click.echo(click.style(str(poster), fg="white"))
  return posters  

def validate_extra_posters(extra_posters):
  """ Make sure this is a dictionary. 
  Each key should be an integer.
  Each value should be a dictionary with key poster-ids. 
  The value of poster-ids should be a list of integer ids.
  """
  if not isinstance(extra_posters, dict):
    raise ValueError("extra_posters must be a dictionary")
  
  for key, value in extra_posters.items():
    if not isinstance(key, int):
      raise ValueError("Keys in extra_posters must be integers")
    if not isinstance(value, dict):
      raise ValueError("Values in extra_posters must be dictionaries")
    for poster_id, ids in value.items():
      if not isinstance(poster_id, str):
        raise ValueError("Keys in poster-ids must be strings")
      if not isinstance(ids, list):
        raise ValueError("Values in poster-ids must be lists")
      if not all(isinstance(id, int) for id in ids):
        raise ValueError("Elements in poster-ids lists must be integers")

def validate_manual_matches(matches):
  """ Make sure this is a list. 
  Each entry should have keys: 'session_id', 'poster_id', 'title_in_session', 'matched_title' """
  if not isinstance(matches, list):
    raise ValueError("matches must be a list")
  
  for match in matches:
    if not isinstance(match, dict):
      raise ValueError("Elements in matches must be dictionaries")
    if not all(key in match for key in ['session_id', 'poster_id', 'title_in_session', 'matched_title']):
      raise ValueError("Elements in matches must have keys: 'session_id', 'poster_id', 'title_in_session', 'matched_title'")
    if not isinstance(match['session_id'], int):
      raise ValueError("session_id must be an integer")
    if not isinstance(match['poster_id'], int):
      raise ValueError("poster_id must be an integer")
    if not isinstance(match['title_in_session'], str):
      raise ValueError("title_in_session must be a string")
    if not isinstance(match['matched_title'], str):
      raise ValueError("matched_title must be a string")

def validate_missing_list(missing_list):
  """ Make sure the missing list of posters is a list of dictionaries
  with keys "title_in_session" and "sesson_id" """
  if not isinstance(missing_list, list):
    raise ValueError("missing_list must be a list")
  
  for missing in missing_list:
    if not isinstance(missing, dict):
      raise ValueError("Elements in missing_list must be dictionaries")
    if not all(key in missing for key in ['session_id', 'title_in_session']):
      raise ValueError("Elements in missing_list must have keys: 'session_id', 'title_in_session'")
    if not isinstance(missing['session_id'], int):
      raise ValueError("session_id must be an integer")
    if not isinstance(missing['title_in_session'], str):
      raise ValueError("title_in_session must be a string")
        
def update_manual_match(known_matches, session_id, title_in_session, poster_id, matched_title):
  """ Update the known matches with the new match, but check if it's already there,
   and update that record instead.  """
  for match in known_matches:
    if match['session_id'] == session_id and match['title_in_session'] == title_in_session:
      match['poster_id'] = poster_id
      match['matched_title'] = matched_title
      return known_matches # stop here! 
  # if we didn't find it and return from the loop   
  known_matches.append({
    'session_id': session_id,
    'title_in_session': title_in_session,
    'poster_id': poster_id,
    'matched_title': matched_title
  })
  return known_matches

def update_manual_match_with_cache(known_matches, session_id, title_in_session, poster_id, matched_title, match_cache_path):
  """ Update the known matches with the new match, but check if it's already there,
   and update that record instead.  """
  known_matches = update_manual_match(known_matches, session_id, title_in_session, poster_id, matched_title)
  save_as_yaml(known_matches, match_cache_path)
  return known_matches

# people might be an array, or a list of names, or not present
# or null or a whole load of other things, so this needs
# to be very robust 
def get_people_from_poster(poster):
  people = poster.get('people', '')
  if people:
    if isinstance(people, str):
      return people
    elif isinstance(people, list):
      return ', '.join(people)
    else:
      return str(people)
  return ''

class Matcher:
  def __init__(self, 
               minisymposium_posters: List[Dict[str, Any]], 
               posters: List[Dict[str, Any]], 
               known_manual_matches: List[Dict[str, Any]], 
               missing_posters: List[Dict[str, Any]],
               extra_posters: Dict[int, Dict[str, Any]], 
               match_cache_path: str, 
               missing_poster_cache_path: str,
               threshold: int,
               name_threshold: int):
    
    self.minisymposium_posters = minisymposium_posters
    self.posters = posters
    self.known_manual_matches = known_manual_matches
    self.missing_posters = missing_posters
    self.extra_posters = extra_posters
    self.match_cache_path = match_cache_path
    self.missing_poster_cache_path = missing_poster_cache_path

    self.threshold = threshold
    self.name_threshold = name_threshold

    self.results = {} 
    self.is_poster_matched = { poster["id"]:False for poster in posters }
    self.matched_posters = []
    self.unmatched_posters = []

    self.poster_id_index = { int(poster["id"]):poster for poster in posters }

    # index the manual matches... 
    manual_match_index = {}
    for match in known_manual_matches:
      manual_match_index[(match['session_id'], match['title_in_session'])] = match

    self.manual_match_index = manual_match_index

  def find_threshold_match(self, poster: Dict[str, Any]):
    THRESHOLD = self.threshold
    NAME_THRESHOLD = self.name_threshold
    posters = self.posters 

    title = poster['title']
    match = process.extractOne(title, [p['title'] for p in posters], scorer=fuzz.token_sort_ratio)
    if match and match[1] > THRESHOLD:  # threshold for matching
      matched_poster = next(p for p in posters if p['title'] == match[0])
      return matched_poster
    elif match and match[1] <= THRESHOLD:
      # print a warning for low similarity, not matching... 
      # Secondary match based on person name if title similarity is low
      people = get_people_from_poster(poster)
      if len(people) > 0:
        name_match = process.extractOne(people, [f"{p['first_name']} {p['last_name']}" for p in posters], scorer=fuzz.token_sort_ratio)
        if name_match and name_match[1] > NAME_THRESHOLD:
          matched_poster = next(p for p in posters if f"{p['first_name']} {p['last_name']}" == name_match[0])
          return matched_poster
    return None

  def update_missing_poster(self, session_code: int, title_in_session: str):
    """ Add a missing poster entry to the missing_posters list and save it to the cache """
    # make sure we aren't adding a duplicate
    if any(p['session_id'] == session_code and p['title_in_session'] == title_in_session for p in self.missing_posters):
      warning(f"Duplicate missing poster entry for session {session_code} with title '{title_in_session}'")
      return
    
    self.missing_posters.append({
      'session_id': session_code,
      'title_in_session': title_in_session
    })
    save_as_yaml(self.missing_posters, self.missing_poster_cache_path)

  def match(self, session_code: int, title_in_session: str, matched_poster): 
    """ Update the matched_posters list and is_poster_matched dictionary """
    poster_id = matched_poster["id"]
    matched_title = matched_poster["title"]


    if poster_id not in self.is_poster_matched:
      raise ValueError(f"poster_id {poster_id} not found in is_poster_matched dictionary")
    
    if self.is_poster_matched[poster_id] == True: 
      # find the previous match
      previous_match = next((p for p in self.matched_posters if p['poster_id'] == poster_id), None)
      if previous_match is None:
        message = " we can't find a match, so this indicates a data structure error. "
      else: 
        message = f" it was matched to '{previous_match['title_in_session']}' in session {previous_match['session_code']}. "
      warning(f"Double matched poster id: {poster_id} with title {matched_title} in session {session_code} matched title '{title_in_session}' and " + message)

    debug_print(f"Matched poster id {poster_id} in session {session_code}: '{title_in_session}' to '{matched_title}'")

    self.is_poster_matched[poster_id] = True
    self.matched_posters.append({
      'session_code': session_code,
      'poster_id': poster_id,
      'title_in_session': title_in_session,
      'matched_title': matched_title
    })

    self.results[session_code]['posters'].append(matched_title)
    self.results[session_code]['poster-ids'].append(poster_id)
    self.results[session_code]['poster-presenters'].append(f"{matched_poster['first_name']} {matched_poster['last_name']}")
    self.results[session_code]['poster-emails'].append(matched_poster['email'])

  def run_match(self):
    for symposium in self.minisymposium_posters:
      session_code = int(symposium['url'].split('SESSIONCODE=')[-1])

      self.results[session_code] = {'posters': [], 'poster-emails': [], 'poster-ids': [], 'poster-presenters': [], 'missing-posters': []}

      nextramatches = 0 
      if session_code in self.extra_posters: # there could be extra posters. 
        for poster_id in self.extra_posters[session_code]["poster-ids"]:
          self.match(session_code, "Extra Poster", self.poster_id_index[poster_id])
          nextramatches += 1  
          
      if 'posters' not in symposium or 'posters' not in symposium['posters']:
        if nextramatches == 0: 
          warning(f"No posters found for session '{session_code}' and no extra matches found in extra_posters")
        else: 
          warning(f"No posters found for session '{session_code}' and {nextramatches} extra matches found in extra_posters")
        continue

      posters_data = symposium['posters']['posters']

      for poster in posters_data:
        manual_match = self.manual_match_index.get((session_code, poster["title"]), None)
        if manual_match:
          matched_poster = self.poster_id_index.get(manual_match["poster_id"], None)
          if matched_poster is not None:
            self.match(session_code, poster["title"], matched_poster)
          else:
            warning(f"Manual match found for poster {poster['title']} in session {session_code} but poster not found in posters list")
          continue

        poster_match = self.find_threshold_match(poster) # find a definite match if we can
        if poster_match is not None: 
          self.match(session_code, poster["title"], poster_match)
          continue 
        else: 
          self.unmatched_posters.append((session_code, poster))
      
    # now run through the unmatched posters and record them in the cache
    self.handle_unmatched_posters()

    return self.results
  
  def handle_unmatched_posters(self):
    for (session_code, poster) in self.unmatched_posters:
      people = get_people_from_poster(poster)
      # check for this entry in unmatched_posters
      if any(p['session_id'] == session_code and p['title_in_session'] == poster["title"] for p in self.missing_posters):
        if len(people) > 0: 
          self.results[session_code]['missing-posters'].append(poster['title'] + " ----- " + people)
        else: 
          self.results[session_code]['missing-posters'].append(poster['title'])
        continue 

      mmatch = self.manual_match(poster)
      if mmatch is not None:
        matched_poster = next(p for p in self.posters if p['id'] == mmatch['id'])
        self.match(session_code, poster["title"], matched_poster)
        update_manual_match_with_cache(self.known_manual_matches, session_code, poster["title"], matched_poster["id"], matched_poster["title"], self.match_cache_path)
      else:
        self.update_missing_poster(session_code, poster["title"])
        if len(people) > 0: 
          self.results[session_code]['missing-posters'].append(poster['title'] + " ----- " + people)
        else: 
          self.results[session_code]['missing-posters'].append(poster['title'])

  def manual_match(self, poster):
    title = poster['title']
    people = get_people_from_poster(poster)

    title_matches = process.extract(title, [p['title'] for p in self.posters], scorer=fuzz.token_sort_ratio, limit=5)
    name_matches = process.extract(people, [f"{p['first_name']} {p['last_name']}" for p in self.posters], scorer=fuzz.token_sort_ratio, limit=5) if people else []

    console.print("\nPoster Title: " + "[bold]" + title + "[/bold]")
    console.print("Top 5 Title Matches:")
    for i, (match_title, score) in enumerate(title_matches, 1):
      matched_poster = next(p for p in self.posters if p['title'] == match_title)
      already_matched = self.is_poster_matched[matched_poster['id']]
      posterby = matched_poster['first_name'] + " " + matched_poster['last_name']
      console.print(f"{i}. [Title: {matched_poster['title']}, By: {posterby}, ID: {matched_poster['id']}, Score: {score}]")
      if already_matched:
        # get match info from matched_posters
        matched_info = next(p for p in self.matched_posters if p['poster_id'] == matched_poster['id'])
        console.print(f"   [darkred]This poster is already matched to Title: {matched_info['title_in_session']} in session {matched_info['session_code']}[/darkred]")

    if people:
      console.print("\nPresenter Name: " + "[bold]" + people + "[/bold]")
      console.print("Top 5 Name Matches:")
      for i, (match_name, score) in enumerate(name_matches, 1):
        matched_poster = next(p for p in self.posters if f"{p['first_name']} {p['last_name']}" == match_name)
        already_matched = self.is_poster_matched[matched_poster['id']]
        console.print(f"{i}. [Name: {match_name}, ID: {matched_poster['id']}, Score: {score}]")
        if already_matched:
          # get match info from matched_posters
          matched_info = next(p for p in self.matched_posters if p['poster_id'] == matched_poster['id'])
          console.print(f"   [darkred]This poster is already matched to Title: {matched_info['title_in_session']} in session {matched_info['session_code']}[/darkred]")
    
    while True: 
      choice = click.prompt("Enter the ID of the correct match, or enter 'm' for missing", type=str)

      if choice.lower() == 'm':
        return None
      else:
        try:
          poster_id = int(choice)
          matched_poster = next((p for p in self.posters if p['id'] == poster_id), None)
          if matched_poster is not None:
            return matched_poster
          else:
            warning(f"Invalid poster ID: {poster_id}")
            return None
        except ValueError:
          warning("Invalid input. Please enter a valid poster ID or enter 'm' for missing.")
          return None
    
@click.command()
@click.option('--json-file', 'json_file_path', default="processed_minisymposium_records.json", show_default=True, required=True, help='Path to the JSON file containing minisymposium records with extracted poster info')
@click.option('--posters-csv-file', 'csv_file_path', default="posters.csv", show_default=True, required=True, help='Path to the CSV file containing poster information saved from the SIAM spreadsheet')
@click.option('--output-file', 'output_yaml_path', default="matched_posters.yaml", show_default=True, required=True, help='Path to save the output YAML file')
@click.option('--manual-match-cache', 'match_cache_path', default="matched_posters_cache_of_manual_matches.yaml", show_default=True, required=True, help='Path of file to store manual matches')
@click.option('--threshold', default=DEFAULT_THRESHOLD, help='Similarity threshold for matching titles', show_default=True)
@click.option('--name-threshold', 'name_threshold', default=DEFAULT_NAME_THRESHOLD, help='Similarity threshold for matching titles', show_default=True)
@click.option('--debug', is_flag=True, help='Enable debug mode')
@click.option('--missing-poster-cache', 'missing_poster_cache_path', default="matched_posters_cache_of_missing_posters.yaml", show_default=True, help='Path of file to store missing poster entries')
@click.option("--extra-posters-yaml", "extra_posters_yaml_path",  help="Path to the YAML file containing extra posters that have been matched. This file must have keys for the minisymposium id and a list of poster-ids with the known matches")
def main(json_file_path, 
         csv_file_path, 
         output_yaml_path, 
         match_cache_path, 
         threshold, 
         name_threshold, 
         debug, 
         missing_poster_cache_path,
         extra_posters_yaml_path):
  # show parameters if debug and set globals. 
  global DEBUG, THRESHOLD, NAME_THRESHOLD
  DEBUG = debug 
  THRESHOLD = threshold
  NAME_THRESHOLD = name_threshold
  if DEBUG:
    debug_print("Parameters:")
    click.echo(f"JSON file: {json_file_path}")
    click.echo(f"CSV file: {csv_file_path}")
    click.echo(f"Output file: {output_yaml_path}")
    click.echo(f"Manual match cache: {match_cache_path}")
    click.echo(f"Threshold: {threshold}")
    click.echo(f"Name threshold: {name_threshold}")
    click.echo(f"Debug mode: {'on' if debug else 'off'}")
    click.echo(f"Extra posters yaml: {extra_posters_yaml_path}")

  # load extra poster info
  extra_posters = read_yaml(extra_posters_yaml_path) if extra_posters_yaml_path and os.path.exists(extra_posters_yaml_path) else {}
  debug_print(f"Loaded {len(extra_posters)} poster groups from extra posters YAML file {extra_posters_yaml_path}")
  validate_extra_posters(extra_posters)
  debug_print("Extra posters are valid")

  # load the known manual matches
  known_manual_matches = read_yaml(match_cache_path) if match_cache_path and os.path.exists(match_cache_path) else []
  debug_print(f"Loaded {len(known_manual_matches)} known manual matches file {match_cache_path}")
  validate_manual_matches(known_manual_matches)
  debug_print("Known manual matches are valid")

  # load the missing poster list
  missing_posters = read_yaml(missing_poster_cache_path) if missing_poster_cache_path and os.path.exists(missing_poster_cache_path) else []
  debug_print(f"Loaded {len(missing_posters)} missing posters from {missing_poster_cache_path}")
  validate_missing_list(missing_posters)
  debug_print("Missing posters are valid")

  # load the minisymposium poster records
  minisymposium_posters = read_json(json_file_path)
  debug_print(f"Loaded {len(minisymposium_posters)} minisymposium poster records from {json_file_path}")

  # load the poster records TODO -- read these from a YAML file... 
  posters = read_posters_csv(csv_file_path)
  debug_print(f"Loaded {len(posters)} posters from {csv_file_path}")

  matcher = Matcher(minisymposium_posters, 
                    posters, 
                    known_manual_matches, 
                    missing_posters, 
                    extra_posters, 
                    match_cache_path, 
                    missing_poster_cache_path,
                    threshold,
                    name_threshold)

  # this will automatically update the match_cache_path with any new matches
  results = matcher.run_match()

  # Save results to YAML file
  save_as_yaml(results, output_yaml_path)

if __name__ == '__main__':
  main()