import sys
from PyQt5.QtWidgets import QApplication, QWidget, QPushButton, QVBoxLayout, QTextEdit, QMessageBox
import csv
import re

def load_sessions(filename):
    with open(filename, 'r') as file:
        content = file.read()
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

class ReviewWindow(QWidget):
    def __init__(self, sessions):
        super().__init__()
        self.sessions = sessions
        self.current_index = 0
        self.initUI()

    def initUI(self):
        self.textEdit = QTextEdit(self)
        self.textEdit.setReadOnly(True)
        self.approveButton = QPushButton('Approve', self)
        self.flagButton = QPushButton('Flag', self)

        self.approveButton.clicked.connect(self.approve)
        self.flagButton.clicked.connect(self.flag)

        layout = QVBoxLayout()
        layout.addWidget(self.textEdit)
        layout.addWidget(self.approveButton)
        layout.addWidget(self.flagButton)
        self.setLayout(layout)

        self.setGeometry(300, 300, 350, 300)
        self.setWindowTitle('Session Review')
        self.show()
        self.show_session()

    def show_session(self):
        if self.current_index < len(self.sessions):
            session = self.sessions[self.current_index]
            session_code, title, session_text = session
            self.textEdit.setText(f"SESSIONCODE: {session_code}\nTitle: {title}\n\n{session_text}")
        else:
            QMessageBox.information(self, 'Finished', 'No more sessions to review.')
            self.close()

    def approve(self):
        self.record_decision('Approved')
    
    def flag(self):
        self.record_decision('Flagged')

    def record_decision(self, decision):
        session = self.sessions[self.current_index]
        session_code, title, _ = session
        save_result(session_code, title, decision)
        self.current_index += 1
        self.show_session()

# Main application
app = QApplication(sys.argv)
filename = 'mini_symposium_info.txt'  # This should be the path to your input file
sessions = load_sessions(filename)
ex = ReviewWindow(sessions)
sys.exit(app.exec_())
