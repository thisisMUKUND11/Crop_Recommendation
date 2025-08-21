document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('login-form');

    loginForm.addEventListener('submit', (event) => {
        event.preventDefault();

        const username = document.getElementById('username').value;
        const password = document.getElementById('password').value;

        // --- Sample Credentials ---
        const validCredentials = {
            'admin': 'password',
            'user1': '12345',
            'user2': 'abcde'
        };

        // Retrieve users from localStorage
        const storedUsers = JSON.parse(localStorage.getItem('users')) || {};

        if ((validCredentials[username] && validCredentials[username] === password) || (storedUsers[username] && storedUsers[username] === password)) {
            // Successful login: redirect to the main application page
            window.location.href = 'index.html';
        } else {
            // Failed login: show an error message
            alert('Invalid username or password.');
        }
    });
});
