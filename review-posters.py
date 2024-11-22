import tkinter as tk
from tkinter import scrolledtext
import csv
import re

def load_sessions(filename):
    with open(filename, 'r') as file:
        content = file.read()

    # Split sessions based on double dashed lines
    sessions = re.split(r'-{3,}', content)
    session_data = []

    for session in sessions:
        session_code_search = re.search(r'SESSIONCODE=(\d+)', session)
        title_search = re.search(r'Title:\s+(.+)', session)

        if session_code_search and title_search:
            session_code = session_code_search.group(1)
            title = title_search.group(1).strip()
            session_data.append((session_code, title, session))

    return session_data

def save_result(session_code, title, flagged):
    with open('session_reviews.txt', 'a', newline='') as file:
        writer = csv.writer(file)
        writer.writerow([session_code, title, flagged])

def review_sessions(sessions):
    def show_session(index):
        session_info = sessions[index]
        session_code, title, session_text = session_info
        text_area.config(state=tk.NORMAL)
        text_area.delete('1.0', tk.END)
        text_area.insert(tk.END, f"SESSIONCODE: {session_code}\nTitle: {title}\n\n{session_text}")
        text_area.config(state=tk.DISABLED)

    def approve():
        session_info = sessions[index[0]]
        session_code, title, _ = session_info
        save_result(session_code, title, 'Approved')
        next_session()

    def flag():
        session_info = sessions[index[0]]
        session_code, title, _ = session_info
        save_result(session_code, title, 'Flagged')
        next_session()

    def next_session():
        index[0] += 1
        if index[0] < len(sessions):
            show_session(index[0])
        else:
            root.destroy()

    root = tk.Tk()
    root.title("Mini Symposium Review")
    
    text_area = scrolledtext.ScrolledText(root, width=100, height=40)
    text_area.pack(padx=10, pady=10)
    text_area.config(state=tk.DISABLED)

    approve_button = tk.Button(root, text="Approve", command=approve)
    approve_button.pack(side=tk.LEFT, padx=20, pady=20)

    flag_button = tk.Button(root, text="Flag", command=flag)
    flag_button.pack(side=tk.RIGHT, padx=20, pady=20)

    index = [0]
    show_session(index[0])

    root.mainloop()

# Usage
filename = 'mini_symposium_info.txt'  # This should be the path to your input file
sessions = load_sessions(filename)
review_sessions(sessions)
