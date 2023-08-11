import React, { useEffect, useState } from 'react';
import { TokenAddress, TokenABI, ContractAddress, ContractABI } from './globalVariables.js';

const { ethers } = require("ethers");

function App() {
  const [amount, setAmount] = useState(0);
  const [choice, setChoice] = useState(0);
  const [winnerChoice, setWinnerChoice] = useState(0);

  useEffect(() => {
    // No es necesario el bloque "init" ya que no necesitas obtener una dirección de MetaMask aquí
  }, []);

  const connectToContract = async () => {
    if (typeof window.ethereum !== 'undefined') {
      try {
        // Solicitar al usuario que autorice la conexión
        await window.ethereum.enable();
        
        // Crear el proveedor y el signer
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const signer = provider.getSigner();
        
        console.log(ethers.version);
        console.log(await provider.listAccounts());

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
      } catch (error) {
        console.error('Error connecting to MetaMask:', error);
      }
    } else {
      // MetaMask no está instalado o habilitado
      console.log('MetaMask is not installed or enabled.');
    }
  };

  const finalizeBetsAndRefund = async () => {
    if (typeof window.ethereum !== 'undefined') {
      try {
        // Solicitar al usuario que autorice la conexión
        await window.ethereum.enable();
        
        // Crear el proveedor y el signer
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const signer = provider.getSigner();

        const contract = new ethers.Contract(ContractAddress, ContractABI, signer);

        try {
          // Llamar a la función finalizeBetsAndRefund
          const tx = await contract.finalizeBetsAndRefund();
          await tx.wait();
          console.log('Finalize bets and refund successful!');
        } catch (error) {
          console.error('Error finalizing bets and refund:', error);
        }
      } catch (error) {
        console.error('Error connecting to MetaMask:', error);
      }
    } else {
      console.log('MetaMask is not installed or enabled.');
    }
  };

  const winner = async () => {
    if (typeof window.ethereum !== 'undefined') {
      try {
        // Solicitar al usuario que autorice la conexión
        await window.ethereum.enable();
        
        // Crear el proveedor y el signer
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const signer = provider.getSigner();

        const contract = new ethers.Contract(ContractAddress, ContractABI, signer);

        try {
          // Llamar a la función winner con el parámetro _choice
          const tx = await contract.winner(winnerChoice);
          await tx.wait();
          console.log('Winner function executed successfully!');
        } catch (error) {
          console.error('Error executing winner function:', error);
        }
      } catch (error) {
        console.error('Error connecting to MetaMask:', error);
      }
    } else {
      console.log('MetaMask is not installed or enabled.');
    }
  };

  return (
    <div>
      <input type="number" placeholder="Amount" value={amount} onChange={e => setAmount(e.target.value)} />
      <input type="number" placeholder="Choice" value={choice} onChange={e => setChoice(e.target.value)} />
      <button onClick={connectToContract}>Place Bet</button>

      <button onClick={finalizeBetsAndRefund}>Finalize Bets and Refund</button>

      <input type="number" placeholder="Winner Choice" value={winnerChoice} onChange={e => setWinnerChoice(e.target.value)} />
      <button onClick={winner}>Declare Winner</button>
    </div>
  );
}

export default App;
