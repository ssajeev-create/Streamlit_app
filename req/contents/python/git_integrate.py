import streamlit as st
from git import Repo
import os

REPO_PATH = r"C:\Users\ssajeev\Downloads\python\dummy_sql_file"  

st.title("Git Branch & SQL File Downloader")

# Open repo
repo = Repo(REPO_PATH)

# Get branches
branch_names = [head.name for head in repo.heads]
selected_branch = st.selectbox("Select Branch to Search SQL Files", branch_names)

if st.button("Show SQL Files in Selected Branch"):
    # Checkout the selected branch
    repo.git.checkout(selected_branch)

    tree = repo.head.commit.tree

    sql_files = [item.path for item in tree.traverse() if item.type == "blob" and item.path.endswith('.sql')]

    if sql_files:
        st.write(f"SQL files in branch **{selected_branch}**:")
        for rel_path in sql_files:
            abs_file_path = os.path.join(REPO_PATH, rel_path)
            if os.path.exists(abs_file_path):
                with open(abs_file_path, "rb") as f:
                    file_bytes = f.read()
                st.download_button(
                    label=f"Download {rel_path}",
                    data=file_bytes,
                    file_name=rel_path,
                    mime="text/sql"
                )
            else:
                st.warning(f"{rel_path} is not present in your working directory. Did you run 'git checkout'?")
    else:
        st.info(f"No SQL files found in branch **{selected_branch}**.")
