import re

def has_sufficient_posters(session_text):
    # Initialize total poster count
    total_posters = 0
    
    # Check for generic 'Associated Poster:' entries
    total_posters += len(re.findall(r'Associated Poster:', session_text))
    
    # Check for a grouped list of posters after 'Associated posters'
    grouped_posters_sections = re.findall(r'Associated Posters?:\s*(.*?)(?:<P>|$)', session_text, re.IGNORECASE | re.DOTALL)
    
    for section in grouped_posters_sections:
        # Check for numbered list of posters in this section
        numbered_posters = re.findall(r'\b\d+\.\s+[^;]+;', section)
        total_posters += len(numbered_posters)
    
    # Check if there are at least four posters
    return total_posters >= 4

def process_symposium_sessions(filename):
    with open(filename, 'r') as file:
        content = file.read()

    # Split sessions based on double dashed lines
    sessions = re.split(r'-{3,}', content)

    results = []
    for session in sessions:
        session_code_search = re.search(r'SESSIONCODE=(\d+)', session)
        title_search = re.search(r'Title:\s+(.+)', session)

        if session_code_search and title_search:
            session_code = session_code_search.group(1)
            title = title_search.group(1).strip()

            # Extract all organizers
            organizers = re.findall(r'<b>([^<]+)</b><br>\s*<i>([^<]*)</i>', session)
            organizers_info = ', '.join([f"{name.strip()} ({affiliation.strip()})" if affiliation else name.strip() for name, affiliation in organizers])

            # Check if the session has sufficient posters
            if not has_sufficient_posters(session):
                results.append((session_code, title, organizers_info))

    return results

# Example usage:
results = process_symposium_sessions('mini_symposium_info.txt')
for result in results:
    print(f"SESSIONCODE: {result[0]}")
    print(f"Title: {result[1]}")
    print(f"Organizers: {result[2]}\n")
