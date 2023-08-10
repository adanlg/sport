const { ethers } = require("ethers");

const getBlockchain = () =>
  new Promise((resolve, reject) => {
    window.addEventListener('load', async () => {
      if(window.ethereum) {
        await window.ethereum.request({ method: 'eth_requestAccounts' });
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = provider.getSigner();
        const signerAddress = await signer.getAddress();

        resolve({signerAddress});
      }
      resolve({signerAddress: undefined});
    });
  });

export default getBlockchain;