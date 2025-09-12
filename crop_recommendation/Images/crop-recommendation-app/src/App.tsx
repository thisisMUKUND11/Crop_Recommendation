import React from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import Navbar from './components/Navbar';
import ImagePage from './pages/ImagePage';
import LanguageSelectionPage from './pages/LanguageSelectionPage';
import TermsAndConditionsPage from './pages/TermsAndConditionsPage';

const App: React.FC = () => {
  return (
    <Router>
      <Navbar />
      <Routes>
        <Route path="/image/:id" element={<ImagePage />} />
        <Route path="/language-selection" element={<LanguageSelectionPage />} />
        <Route path="/terms-and-conditions" element={<TermsAndConditionsPage />} />
        <Route path="/" element={<Home />} />
      </Routes>
    </Router>
  );
};

const Home: React.FC = () => {
  return (
    <div className="container d-flex flex-column justify-content-center align-items-center vh-100">
      <h2>Welcome to the Crop Recommendation App!</h2>
      <p>Please select an image from the navigation bar to view it.</p>
    </div>
  );
};

export default App;