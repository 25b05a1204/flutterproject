const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { defineString, defineSecret } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const nodemailer = require('nodemailer');
initializeApp();
const SMTP_HOST = defineString('SMTP_HOST', { default: 'smtp.gmail.com' });
const SMTP_PORT = defineString('SMTP_PORT', { default: '465' });
const SMTP_USER = defineString('SMTP_USER');
const SMTP_PASSWORD = defineSecret('SMTP_PASSWORD');

exports.emailNewDoubtRequest = onDocumentCreated({ document: 'notifications/{notificationId}', secrets: [SMTP_PASSWORD] }, async (event) => {
  const notification = event.data?.data();
  if (!notification || !notification.recipientId) return;
  const userDoc = await getFirestore().collection('users').doc(notification.recipientId).get();
  const email = userDoc.data()?.email;
  if (!email) return;
  const user = SMTP_USER.value();
  const password = SMTP_PASSWORD.value();
  if (!user || !password) {
    console.warn('SMTP credentials are not configured; in-app notification was saved, email skipped.');
    return;
  }
  const transporter = nodemailer.createTransport({ host: SMTP_HOST.value(), port: Number(SMTP_PORT.value() || 465), secure: Number(SMTP_PORT.value() || 465) === 465, auth: { user, pass: password } });
  await transporter.sendMail({ from: `ConnectUp Study Buddy <${user}>`, to: email, subject: notification.title || 'New Study Buddy notification', text: `${notification.body || 'You have a new notification.'}\n\nOpen ConnectUp Study Buddy to view the request.` });
});
