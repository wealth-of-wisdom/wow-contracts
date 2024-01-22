import os
from os import sep

from pathlib import Path
from requests_toolbelt.multipart.encoder import MultipartEncoder
import requests

JWT = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySW5mb3JtYXRpb24iOnsiaWQiOiJlOWU5MDMwZi0wMGE4LTRlNTktYmQxMy1kMTExMThiYmRjNDYiLCJlbWFpbCI6Imtha2FmMTBAZ21haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsInBpbl9wb2xpY3kiOnsicmVnaW9ucyI6W3siaWQiOiJGUkExIiwiZGVzaXJlZFJlcGxpY2F0aW9uQ291bnQiOjF9XSwidmVyc2lvbiI6MX0sIm1mYV9lbmFibGVkIjpmYWxzZSwic3RhdHVzIjoiQUNUSVZFIn0sImF1dGhlbnRpY2F0aW9uVHlwZSI6InNjb3BlZEtleSIsInNjb3BlZEtleUtleSI6Ijg3YzAyN2VlZjhkMjFjMTk0M2FhIiwic2NvcGVkS2V5U2VjcmV0IjoiMDg1OTMwMjVmNGZkNzAzMjM0MThhNGE3MDQyZjk4NzJmYThkMjljM2E0ODNkNWQ0YmIyZDEwZTU3NzUxN2ViZSIsImlhdCI6MTcwNTk0NDA3NH0.UkfNChtekIAWBHOolFZnMFs5l1x1oGHEaQpFGlROFR0'

def pin_directory_to_pinata(src):
    url = "https://api.pinata.cloud/pinning/pinFileToIPFS"

    try:
        files = []
        for root, _, file_names in os.walk(src):
            for file_name in file_names:
                file_path = os.path.join(root, file_name)
                files.append(("file", (sep.join(file_path.split(sep)[-2:]), open(file_path, "rb"))))

        multipart_data = MultipartEncoder(fields=files)

        headers = {
            "Content-Type": multipart_data.content_type,
            "Authorization": JWT,
        }

        response = requests.post(url, headers=headers, data=multipart_data)

        print(response.json())

    except Exception as e:
        print(e)


metadata_folder_base_path = "metadata"

# Example usage: Loop through levels 1 to 5
for level in range(1, 6):
    metadata_folder = Path(metadata_folder_base_path) / f"test_metadata_level{str(level).zfill(2)}"
    absolute_metadata_folder = metadata_folder.resolve()
    pin_directory_to_pinata(absolute_metadata_folder)
