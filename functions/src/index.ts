import {getAuth} from "firebase-admin/auth";
import {initializeApp} from "firebase-admin/app";
import {setGlobalOptions} from "firebase-functions/v2";
import {HttpsError, onCall} from "firebase-functions/v2/https";

initializeApp();
setGlobalOptions({region: "europe-west1", maxInstances: 10});

const validRoles = new Set(["basic", "premium", "admin"]);

/**
 * Ensures the callable request was made by an admin.
 * @param {Record<string, unknown> | undefined} token Firebase auth token.
 */
function requireAdmin(token: Record<string, unknown> | undefined): void {
  if (token?.role !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "Only admins can manage user roles.",
    );
  }
}

export const setUserRole = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }
  requireAdmin(request.auth.token);

  const uid = request.data?.uid;
  const role = request.data?.role;
  if (typeof uid !== "string" || !uid || !validRoles.has(role)) {
    throw new HttpsError(
      "invalid-argument",
      "A valid uid and role are required.",
    );
  }

  const auth = getAuth();
  const user = await auth.getUser(uid);
  await auth.setCustomUserClaims(uid, {...user.customClaims, role});

  return {success: true, uid, role};
});

export const getUserRole = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }
  requireAdmin(request.auth.token);

  const uid = request.data?.uid;
  if (typeof uid !== "string" || !uid) {
    throw new HttpsError("invalid-argument", "A valid uid is required.");
  }

  const user = await getAuth().getUser(uid);
  const role = validRoles.has(user.customClaims?.role) ?
    user.customClaims?.role :
    "basic";

  return {uid, role, email: user.email ?? null};
});
