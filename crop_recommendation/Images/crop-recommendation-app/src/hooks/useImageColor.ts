import { useState, useEffect } from 'react';
import ColorThief from 'colorthief';

const useImageColor = (imageUrl: string) => {
  const [color, setColor] = useState<number[] | null>(null);

  useEffect(() => {
    const img = new Image();
    img.crossOrigin = 'Anonymous';
    img.src = imageUrl;

    img.onload = () => {
      const colorThief = new ColorThief();
      const dominantColor = colorThief.getColor(img);
      setColor(dominantColor);
    };

    img.onerror = () => {
      console.error('Failed to load image for color extraction:', imageUrl);
      setColor(null);
    };
  }, [imageUrl]);

  return color;
};

export default useImageColor;
