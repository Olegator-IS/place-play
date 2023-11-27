const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendChatNotification = functions.firestore
  .document('eventMessages/{eventId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const eventId = context.params.eventId;
    const messageData = snapshot.data();
    const senderName = messageData.senderName;

    // Получите токены устройств для всех пользователей, участвующих в событии
    const deviceTokens = await getDeviceTokensForEvent(eventId);

    // Отправьте уведомление каждому токену устройства
    const payload = {
      notification: {
        title: 'Новое сообщение в чате',
        body: `${senderName} отправил(а) сообщение`,
      },
    };

    for (const token of deviceTokens) {
      await admin.messaging().sendToDevice(token, payload);
    }
  });

async function getDeviceTokensForEvent(eventId) {
  // Ваш код для получения токенов устройств, связанных с событием
  // Например, запрос к базе данных для получения пользователей и их токенов
  // Помните о безопасности, храните токены устройств в безопасном месте
  // и используйте их ответственно.
}
