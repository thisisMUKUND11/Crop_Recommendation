import React from 'react';
import { Link } from 'react-router-dom';

const Navbar: React.FC = () => {
  return (
    <nav className="navbar navbar-expand-lg navbar-light bg-light">
      <div className="container-fluid">
        <Link className="navbar-brand" to="/">Crop Recommendation</Link>
        <button className="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
          <span className="navbar-toggler-icon"></span>
        </button>
        <div className="collapse navbar-collapse" id="navbarNav">
          <ul className="navbar-nav">
            <li className="nav-item">
              <Link className="nav-link" to="/image/1">Image 1</Link>
            </li>
            <li className="nav-item">
              <Link className="nav-link" to="/image/2">Image 2</Link>
            </li>
            <li className="nav-item">
              <Link className="nav-link" to="/image/3">Image 3</Link>
            </li>
            <li className="nav-item">
              <Link className="nav-link" to="/image/4">Image 4</Link>
            </li>
            <li className="nav-item">
              <Link className="nav-link" to="/image/5">Image 5</Link>
            </li>
            <li className="nav-item">
              <Link className="nav-link" to="/language-selection">Language</Link>
            </li>
            <li className="nav-item">
              <Link className="nav-link" to="/terms-and-conditions">Terms & Conditions</Link>
            </li>
          </ul>
        </div>
      </div>
    </nav>
  );
};

export default Navbar;
