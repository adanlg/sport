import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

const root = document.getElementById('root');

const renderApp = () => {
  ReactDOM.createRoot(root).render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  );
};

if (root.hasChildNodes()) {
  ReactDOM.hydrate(<App />, root, renderApp);
} else {
  renderApp();
}
