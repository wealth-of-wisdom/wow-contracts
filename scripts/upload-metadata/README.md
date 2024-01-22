# Metadata Generation Scripts

These scripts are designed to generate metadata for WOW NFTs  based on a configuration file. The generated metadata includes information such as name, description, image URLs, and various attributes. Scripts organize the metadata into folders based on specified output paths.

## Prerequisites

Before using these scripts, ensure you have the following:

-   Python installed on your system
-   Necessary Python libraries installed. You can install them using:

```bash
pip install requests requests-toolbelt
```

## Configuration

The metadata generation is driven by a configuration file (nftConfig.json), which contains information about the NFTs to be generated. The configuration file is structured with multiple NFT types, each having its own set of parameters such as name prefix, description, image URLs, etc.

Example configuration:

```json
{
        "nft": {
            "name_prefix": "WOW-LVL",
        "description": "Description of NFT",
        "image_urls": [
            "https://ipfs.io/ipfs/image1.jpg",
            "https://ipfs.io/ipfs/image2.jpg"
        ],
        "author": "Author",
        "lifecycle": [12, 15, 24, 40, "Unlimited"],
        "lifecycle_extension": ["Unavailable", 15, 18,"Unlimited" "Unavailable"],
        "prices": [988, 4988, 9988, 32988, 999988],
        "level_quantities": [15, 15, 15, 15, 15],
        "output_folder": "test_metadata_level_nft"
    },

}
```

## Usage

### Generate Metadata:

To generate metadata based on the configuration, run:

```bash
python generate.py
```

The script reads the configuration from nftConfig.json and generates metadata for each NFT type specified in the configuration.

### Output Folder:

The generated metadata is organized into folders based on the specified output path in the configuration.

### Upload to IPFS:

You can modify the pin_directory_to_pinata function in the script to upload the generated metadata to IPFS or any desired platform.

### Prerequisites

- Ensure you have Python installed on your machine.
- Obtain your Pinata JWT key and secret from [Pinata](https://pinata.cloud/).

### Setup

1. Install required Python packages:

    ```bash
    pip install requests requests-toolbelt python-dotenv
    ```

2. Create a `.env` file in the same directory as your script and add your Pinata JWT token:

    ```env
    PINATA_JWT=PINATA_JWT=Bearer {pinata_jwt}
    ```

### Usage

Run the script to upload metadata folders to IPFS:

```bash
python upload_to_ipfs.py
```

## Script Details

The script consists of two main functions:

`pin_directory_to_pinata(src)`: function recursively walks through the specified directory `(src)` and uploads files to IPFS using the Pinata API.

`upload_metadata_folders(metadata_folder_base_path, folder_prefix)`: function uploads metadata folders to IPFS based on the specified `metadata_folder_base_path` and `folder_prefix`. It can be customized for normal and genesis NFT metadata folders.

## Adjust Configuration

Modify the `metadata_folder_base_path` and `folder_prefix` variables in the script to upload different sets of metadata folders.

