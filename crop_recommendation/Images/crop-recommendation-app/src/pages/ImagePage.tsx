import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import useImageColor from '../hooks/useImageColor';

interface ImagePageParams {
  id: string;
}

const images: { [key: string]: string } = {
  '1': require('../assets/160fea8fb41001beab1df8bdb02c148d.jpg'),
  '2': require('../assets/254ff1db7128864fe8f4da0993bd23c2.jpg'),
  '3': require('../assets/77a959d0af926db99f636778907a7e89.jpg'),
  '4': require('../assets/da085bd6e9418897239f27f4e450d6ed.jpg'),
  '5': require('../assets/fbaf797a492d9a5572bebd0064e530f4.jpg'),
};

const ImagePage: React.FC = () => {
  const { id } = useParams<ImagePageParams>();
  const imageUrl = id ? images[id] : '';
  const dominantColor = useImageColor(imageUrl);
  const [textColor, setTextColor] = useState<string>('#000000'); // Default to black

  useEffect(() => {
    if (dominantColor) {
      const [r, g, b] = dominantColor;
      document.body.style.backgroundColor = `rgb(${r}, ${g}, ${b})`;

      // Calculate perceived luminance to determine text color
      const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
      if (luminance > 0.5) {
        setTextColor('#000000'); // Light background, use black text
      } else {
        setTextColor('#FFFFFF'); // Dark background, use white text
      }
    }

    return () => {
      document.body.style.backgroundColor = ''; // Clean up on unmount
      setTextColor('#000000'); // Reset text color
    };
  }, [dominantColor]);

  if (!imageUrl) {
    return <div style={{ color: textColor }}>Image not found.</div>;
  }

  return (
    <div className="container d-flex flex-column justify-content-center align-items-center vh-100">
      <h2 className="mb-4" style={{ color: textColor }}>Image {id}</h2>
      <img src={imageUrl} alt={`Image ${id}`} className="img-fluid rounded shadow" style={{ maxWidth: '80%', maxHeight: '70vh' }} />
    </div>
  );
};

export default ImagePage;
