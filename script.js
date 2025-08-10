document.addEventListener('DOMContentLoaded', () => {
    const recommendBtn = document.getElementById('recommend-btn');
    const districtInput = document.getElementById('district-input');
    const recommendationContainer = document.getElementById('recommendation-container');
    const cropList = document.getElementById('crop-list');

    recommendBtn.addEventListener('click', () => {
        const district = districtInput.value.trim();

        if (district) {
            fetch('/recommend', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ district: district })
            })
                .then(response => response.json())
                .then(data => {
                    if (data.error) {
                        alert(data.error);
                    } else {
                        displayRecommendations(data.recommended_crops);
                    }
                })
                .catch(error => console.error('Error fetching data:', error));
        }
    });

    function displayRecommendations(recommendedCrops) {
        cropList.innerHTML = '';
        if (recommendedCrops.length > 0) {
            recommendedCrops.forEach(crop => {
                const li = document.createElement('li');
                li.textContent = crop;
                cropList.appendChild(li);
            });
        } else {
            const li = document.createElement('li');
            li.textContent = 'No crops match the current conditions.';
            cropList.appendChild(li);
        }
        recommendationContainer.style.display = 'block';
    }
});