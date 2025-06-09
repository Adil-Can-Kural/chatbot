import _ from 'lodash';
window._ = _;

/**
 * We'll load the axios HTTP library which allows us to easily issue requests
 * to our Laravel back-end. This library automatically handles sending the
 * CSRF token as a header based on the value of the "XSRF" token cookie.
 */

import axios from 'axios';
window.axios = axios;

window.axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';

/**
 * Echo exposes an expressive API for subscribing to channels and listening
 * for events that are broadcast by Laravel. Echo and event broadcasting
 * allows your team to easily build robust real-time web applications.
 */

import Echo from 'laravel-echo';
import io from 'socket.io-client';

window.io = io;

// CSRF token'ını güvenli bir şekilde al
const getCsrfToken = () => {
    const tokenElement = document.querySelector('meta[name="csrf-token"]');
    return tokenElement ? tokenElement.getAttribute('content') : '';
};

window.Echo = new Echo({
    broadcaster: 'socket.io',
    host: window.location.hostname + ':6001',
    client: io,
    transports: ['polling', 'websocket'],
    enabledTransports: ['polling', 'websocket'],
    forceTLS: false,
    encrypted: false,
    disableStats: true,
    reconnection: true,
    reconnectionAttempts: 5,
    reconnectionDelay: 3000,
    auth: {
        headers: {
            'X-CSRF-TOKEN': getCsrfToken()
        }
    }
});
