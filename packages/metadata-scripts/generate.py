import os
import json

def generate_metadata(name_prefix, description, image_urls, level, author, lifecycle, lifecycle_extension, prices, quantity):
    metadata_list = []

    for i in range(1, quantity + 1):
        current_name = f"{name_prefix}{level:02d}-#{i}"
        current_metadata = {
            "name": current_name,
            "description": description,
            "image": image_urls[level-1],  # Use the corresponding image URL for the level
            "attributes": [
                {"trait_type": "Author", "value": author},
                {"trait_type": "Lifecycle", "value": str(lifecycle[level-1]) if level <= len(lifecycle) and lifecycle[level-1] not in ["Unavailable", "Unlimited"] else str(lifecycle[level-1])},
                {"trait_type": "Lifecycle extension", "value": str(lifecycle_extension[level-1]) if level <= len(lifecycle_extension) and lifecycle_extension[level-1] not in ["Unavailable", "Unlimited"] else str(lifecycle_extension[level-1])},
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

# Normal NFT information:
name_prefix = "WOW-LVL"
description = "WOW Access Pass NFT: Your key to the world of exclusive crypto opportunities. The WOW Access Pass NFT embodies empowerment, knowledge, trust, and community, offering unparalleled access to high-potential early-stage crypto and NFT projects.\nEnhance your financial journey with curated insights, direct access to expertly vetted ventures, and tailored educational content. With the WOW Access Pass, you're not just participating in crypto; you're joining a movement towards informed and empowered digital asset ownership."
image_urls = [
    "https://ipfs.io/ipfs/QmQEaeoiWpgnzdiMaxLVMjyAHGY7Q1TwaQsojgiuE1iwLa",
    "https://ipfs.io/ipfs/QmUbS1fqupPjUEuyzuRFyWHpCgWhAUQYiUqJYKgScExPuM",
    "https://ipfs.io/ipfs/QmdHg6uYMPqmTWE4x6PvugDYvvsownrQ8CmhDKuDq4EbvY",
    "https://ipfs.io/ipfs/Qmaayndjwqm8tTngNJLaEpDLmUrnT7MLjKv8fM3khjKyFq",
    "https://ipfs.io/ipfs/QmWqRPz9D4kiqoDvfXM7kzmGBhSQ7GQKwNGaMVuXApBUtb"
]
author = "Wealth Of Wisdom"
lifecycle = [12, 15, 24, 40, "Unlimited"]
lifecycle_extension = ["Unavailable", 15, 18, "Unlimited", "Unavailable"]
prices = [988, 4988, 9988, 32988, 999988]
level_quantities = [15, 15, 15, 15, 15]

# Genesis NFT information:
genesis_name_prefix = "WOW-OG-LVL"
genesis_description = "WOW Access Pass NFT: Your key to the world of exclusive crypto opportunities. The WOW Access Pass NFT embodies empowerment, knowledge, trust, and community, offering unparalleled access to high-potential early-stage crypto and NFT projects.\nEnhance your financial journey with curated insights, direct access to expertly vetted ventures, and tailored educational content. With the WOW Access Pass, you're not just participating in crypto; you're joining a movement towards informed and empowered digital asset ownership."
genesis_image_urls = [
    "https://ipfs.io/ipfs/QmQEaeoiWpgnzdiMaxLVMjyAHGY7Q1TwaQsojgiuE1iwLa",
    "https://ipfs.io/ipfs/QmUbS1fqupPjUEuyzuRFyWHpCgWhAUQYiUqJYKgScExPuM",
    "https://ipfs.io/ipfs/QmdHg6uYMPqmTWE4x6PvugDYvvsownrQ8CmhDKuDq4EbvY",
    "https://ipfs.io/ipfs/Qmaayndjwqm8tTngNJLaEpDLmUrnT7MLjKv8fM3khjKyFq",
    "https://ipfs.io/ipfs/QmWqRPz9D4kiqoDvfXM7kzmGBhSQ7GQKwNGaMVuXApBUtb"
]
genesis_author = "Wealth Of Wisdom"
genesis_lifecycle = ["Unlimited", "Unlimited", "Unlimited", "Unlimited", "Unlimited"]
genesis_lifecycle_extension = ["Unavailable", "Unavailable", "Unavailable", "Unavailable", "Unavailable"]
genesis_prices = [988, 4988, 9988, 32988, 999988]
genesis_level_quantities = [15, 15, 15, 15, 15]

metadata_folder = "metadata"

for level, quantity in enumerate(level_quantities, start=1):
    metadata_list = generate_metadata(name_prefix, description, image_urls, level, author, lifecycle, lifecycle_extension, prices, quantity)
    save_metadata(metadata_list, os.path.join(metadata_folder, f"test_metadata_level{level:02d}"))


for level, quantity in enumerate(genesis_level_quantities, start=1):
    metadata_list = generate_metadata(genesis_name_prefix, genesis_description, genesis_image_urls, level, genesis_author, genesis_lifecycle, genesis_lifecycle_extension, genesis_prices, quantity)
    save_metadata(metadata_list, os.path.join(metadata_folder, f"test_metadata_genesis_level{level:02d}"))