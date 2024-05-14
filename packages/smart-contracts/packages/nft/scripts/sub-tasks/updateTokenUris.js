const updateTokenUris = require("../helpers/updateTokenURIs");
require("dotenv").config();

async function main() {
    const nftProxyAddress = process.env.NFT_PROXY_ADDRESS;

    if (!nftProxyAddress) {
        throw new Error("ERROR: NFT proxy address not found")
    }

    await updateTokenUris(nftProxyAddress);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})
