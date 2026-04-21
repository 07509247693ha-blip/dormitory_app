importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

// بيانات مشروعك المأخوذة من قسم الـ web
firebase.initializeApp({
  apiKey: "AIzaSyCbxbMI-2rRgcJJlSlRwYoVSBn2FvMwJ1E",
  appId: "1:689603811376:web:66042446a2ab7d911a35f5",
  messagingSenderId: "689603811376",
  projectId: "dormitory-management-sys-8e843",
});

const messaging = firebase.messaging();