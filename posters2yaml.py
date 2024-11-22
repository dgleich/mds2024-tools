import csv
import yaml
import sys 
import click 
import os 

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

def debug_print(msg, fg="white", debugheader="DEBUG: "):
  global DEBUG
  if DEBUG:
    click.echo(click.style(debugheader + msg, fg=fg))

# Function to read and parse the CSV file
def read_posters_csv(file_path):
  posters = []
  with open(file_path, mode='r', newline='', encoding='utf-8') as csvfile:
    # Skip the first two rows
    next(csvfile)
    next(csvfile)
    reader = csv.DictReader(csvfile)
    for row in reader:
      print(row)
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

@click.command()
@click.option('--posters-csv-file', 'csv_file_path', default="posters.csv", show_default=True, required=True, help='Path to the CSV file containing poster information saved from the SIAM spreadsheet')
@click.option('--posters-yaml-file', 'output_yaml_path', default="posters.yaml", show_default=True, required=True, help='Output PATH to the YAML file containing poster information saved from the SIAM spreadsheet')
@click.option('--debug', is_flag=True, help='Enable debug mode')
@click.option('--force', is_flag=True, help='Force overwrite the output')
def main(csv_file_path, output_yaml_path, debug, force):
  global DEBUG
  DEBUG = debug

  # check that posters yaml file doesn't exist 
  if force == False and os.path.exists(output_yaml_path):
    click.echo(click.style(f"Error: Output YAML file already exists: {output_yaml_path}", fg="red"))
    sys.exit(1)

  posters = read_posters_csv(csv_file_path)

  with open(output_yaml_path, 'w') as file:
    yaml.dump(posters, file)
  debug_print(f"Saved {len(posters)} posters to YAML file: {output_yaml_path}", fg="green")


if __name__ == "__main__":
  main()