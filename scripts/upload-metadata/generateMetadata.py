import os
import json

def generate_metadata(name_prefix, description, image_urls, animation_urls, level, author, lifecycle, prices, quantity):
    metadata_list = []

    for i in range(1, quantity + 1):
        current_name = f"{name_prefix}{level:02d}-#{i}"
        current_metadata = {
            "name": current_name,
            "description": description,
            "image": image_urls[level-1],  # Use the corresponding image URL for the level
            "animation_url": animation_urls[level-1],  # Use the corresponding animation URL for the level
            "attributes": [
                {"trait_type": "Author", "value": author},
                {"trait_type": "Lifecycle", "value": str(lifecycle[level-1]) if level <= len(lifecycle) and lifecycle[level-1] not in ["Unavailable", "Unlimited"] else str(lifecycle[level-1])},
                {"trait_type": "Price", "value": f"{prices[level-1]:,}"}
            ]
        }
        metadata_list.append(current_metadata)

    return metadata_list

def save_metadata(metadata_list, output_directory):
    os.makedirs(output_directory, exist_ok=True)
    for i, metadata in enumerate(metadata_list):
        filename = os.path.join(output_directory, f"{i}.json")
        with open(filename, 'w') as file:
            json.dump(metadata, file, indent=2)

def generate_and_save_metadata(config, output_folder):
    for key, value in config.items():
        for level, quantity in enumerate(value["level_quantities"], start=1):
            metadata_list = generate_metadata(
                value["name_prefix"],
                value["description"],
                value["image_urls"],
                value["animation_urls"],
                level,
                value["author"],
                value["lifecycle"],
                value["prices"],
                quantity
            )
            save_metadata(metadata_list, os.path.join(output_folder, f"metadata_{key}_level{level:02d}"))

# Load config
with open("nftProperties.json") as config_file:
    config = json.load(config_file)

metadata_folder = "metadata"
generate_and_save_metadata(config, metadata_folder)