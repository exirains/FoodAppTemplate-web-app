importScripts('https://www.gstatic.com/firebasejs/10.10.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.10.0/firebase-messaging-compat.js');

const firebaseConfig = {
  apiKey: "AIzaSyBqbADXkTNfZz1o-lD9-e8WEif7NPX1zUw",
  authDomain: "crested-photon-435918-h1.firebaseapp.com",
  projectId: "crested-photon-435918-h1",
  storageBucket: "crested-photon-435918-h1.firebasestorage.app",
  messagingSenderId: "82369512623",
  appId: "1:82369512623:web:4db3b532b00565186f005a",
  measurementId: "G-64CW2P076D"
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
