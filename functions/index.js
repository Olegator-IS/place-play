const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotification = functions.https.onCall(async (data, context) => {
  try {
    const {token, title, body, sender} = data;
    console.log("Token:", token);
    console.log("Title:", title);
    console.log("Sender:", sender);

    if (!token || !title || !sender) {
      throw new Error("Не все обязательные параметры предоставлены");
    }

    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        sender: sender,
      },
      token: token,
    };

    await admin.messaging().send(message);
    return {success: true};
  } catch (error) {
    console.error("Ошибка при вызове sendNotification:", error);
    throw new functions.https.HttpsError("internal", "Ошибка при отпр", error);
  }
});
