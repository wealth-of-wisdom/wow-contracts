interface Web3FunctionHardhat {
    deploy(): Promise<string>
}

export const deployToIPFS = async (
    w3fTask: Web3FunctionHardhat,
): Promise<string> => {
    // Deploy Web3Function on IPFS
    console.log("Deploying Web3Function on IPFS...")
    const cid: string = await w3fTask.deploy()
    if (!cid) throw new Error("IPFS deployment failed")
    console.log(`Web3Function IPFS CID: ${cid}`)

    return cid
}
