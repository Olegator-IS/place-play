const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotification = functions.https.onCall(async (data, context) => {
  try {
    const {token, title, body, sender, sound} = data;
    console.log("Token:", token);
    console.log("Title:", title);
    console.log("Sender:", sender);
    console.log("Sound:", sound);

    if (!token || !title || !sender) {
      throw new Error("Not all required parameters provided");
    }

    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        sender: sender,
        sound: sound,
      },
      token: token,
    };

    console.log("Sending message:", message);

    await admin.messaging().send(message);

    console.log("Message sent successfully"); // Добавьте этот лог

    return {success: true};
  } catch (error) {
    console.error("Error calling sendNotification:", error);
    throw new functions.https.HttpsError("internal", "Error sending ", error);
  }
});

