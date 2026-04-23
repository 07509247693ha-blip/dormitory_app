const admin = require("firebase-admin");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");

admin.initializeApp();

const COMPLAINT_TYPES = new Set(["شكوى/اقتراح", "شكوى", "اقتراح"]);

exports.notifyAdminsOnComplaintCreated = onDocumentCreated(
  "requests/{requestId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const data = snapshot.data();
    const requestType = `${data.type ?? ""}`.trim();
    if (!COMPLAINT_TYPES.has(requestType)) {
      return;
    }

    const studentName = `${data.studentName ?? "طالب"}`.trim();
    const roomNumber = `${data.roomNumber ?? "غير محددة"}`.trim();
    const description = `${data.description ?? ""}`.trim();
    const bodyDetails = description
      ? `من ${studentName} - غرفة ${roomNumber}: ${description}`
      : `من ${studentName} - غرفة ${roomNumber}`;

    const message = {
      topic: "admin_alerts",
      notification: {
        title: "شكوى جديدة من أحد الطلاب",
        body: bodyDetails.slice(0, 180),
      },
      data: {
        type: "complaint",
        requestId: event.params.requestId,
        requestType,
        studentName,
        roomNumber,
      },
    };

    await admin.messaging().send(message);
    logger.info("Admin complaint notification sent", {
      requestId: event.params.requestId,
      requestType,
    });
  },
);

exports.notifyStudentsOnAnnouncementCreated = onDocumentCreated(
  "announcements/{announcementId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const data = snapshot.data();
    const title = `${data.title ?? "إعلان جديد"}`.trim() || "إعلان جديد";
    const body = `${data.body ?? ""}`.trim();

    const message = {
      topic: "announcements",
      notification: {
        title,
        body: body || "تم نشر إعلان جديد من إدارة السكن",
      },
      data: {
        type: "announcement",
        announcementId: event.params.announcementId,
        title,
      },
    };

    await admin.messaging().send(message);
    logger.info("Announcement notification sent", {
      announcementId: event.params.announcementId,
    });
  },
);
