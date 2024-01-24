import os
from pathlib import Path
from dotenv import load_dotenv
from requests_toolbelt.multipart.encoder import MultipartEncoder
import requests

load_dotenv()
JWT = os.getenv("PINATA_JWT")


def pin_directory_to_pinata(src):
    url = "https://api.pinata.cloud/pinning/pinFileToIPFS"

    try:
        files = []
        for root, _, file_names in os.walk(src):
            for file_name in file_names:
                file_path = os.path.join(root, file_name)
                files.append(("file", (os.sep.join(file_path.split(os.sep)[-2:]), open(file_path, "rb"))))

        multipart_data = MultipartEncoder(fields=files)

        headers = {
            "Content-Type": multipart_data.content_type,
            "Authorization": JWT,
        }

        response = requests.post(url, headers=headers, data=multipart_data)

        print(response.json())

    except Exception as e:
        print(e)



def upload_metadata_folders(metadata_folder_base_path, folder_prefix):
    for level in range(1, 2):
        metadata_folder = Path(metadata_folder_base_path) / f"{folder_prefix}{str(level).zfill(2)}"
        absolute_metadata_folder = metadata_folder.resolve()
        print(absolute_metadata_folder)
        pin_directory_to_pinata(absolute_metadata_folder)

metadata_folder_base_path = "metadata"

# normal NFT metadata folders
upload_metadata_folders(metadata_folder_base_path, "test_metadata_nft_level")

# genesis NFT metadata folders
upload_metadata_folders(metadata_folder_base_path, "test_metadata_genesis_nft_level")
