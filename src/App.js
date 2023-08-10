import React, { useEffect, useState } from 'react';
//import getBlockchain from './ethereum.js';
import { TokenAddress, TokenABI, ContractAddress, ContractABI } from './globalVariables.js';

const { ethers } = require("ethers");


function App() {
  const [amount, setAmount] = useState(0);
  const [choice, setChoice] = useState(0);

  useEffect(() => {
    const init = async () => {
      //const { signerAddress } = await getBlockchain();
      // Hacer algo con signerAddress si es necesario
    };
    init();
  }, []);

  const connectToContract = async () => {
    if (typeof window.ethereum !== 'undefined') {
      // MetaMask está instalado
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = provider.getSigner();

      const contract = new ethers.Contract(ContractAddress, ContractABI, signer);
      const tokenContract = new ethers.Contract(TokenAddress, TokenABI, signer);

      try {
        // Realizar la aprobación del token
        const approveTx = await tokenContract.approve(ContractAddress, amount);
        await approveTx.wait();
        console.log('Token approval successful!');

        // Llamar a la función placeBet
        const betTx = await contract.placeBet(amount, choice);
        await betTx.wait();
        console.log('Bet placed successfully!');
      } catch (error) {
        console.error('Error placing bet:', error);
      }
    } else {
      // MetaMask no está instalado o habilitado
      console.log('MetaMask is not installed or enabled.');
    }
  };

  return (
    <div>
      <input type="number" placeholder="Amount" value={amount} onChange={e => setAmount(e.target.value)} />
      <input type="number" placeholder="Choice" value={choice} onChange={e => setChoice(e.target.value)} />
      <button onClick={connectToContract}>Place Bet</button>
    </div>
  );
}

export default App;
