document.addEventListener('DOMContentLoaded', () => {
    const registerForm = document.getElementById('register-form');

    registerForm.addEventListener('submit', (event) => {
        event.preventDefault();

        const username = document.getElementById('username').value.trim();
        const password = document.getElementById('password').value;
        const confirmPassword = document.getElementById('confirm-password').value;

        if (password !== confirmPassword) {
            alert('Passwords do not match.');
            return;
        }

        // Retrieve existing users from localStorage
        let users = JSON.parse(localStorage.getItem('users')) || {};

        if (users[username]) {
            alert('Username already exists.');
            return;
        }

        // Add the new user
        users[username] = password;

        // Save the updated users object back to localStorage
        localStorage.setItem('users', JSON.stringify(users));

        alert('Registration successful! Please login.');
        window.location.href = 'login.html';
    });
});
