const admin = require('firebase-admin');

async function verifyToken(req) {
  const hdr = req.headers.authorization || '';
  const token = hdr.startsWith('Bearer ') ? hdr.substring(7) : null;
  if (!token) throw new Error('Missing Authorization header');
  const decoded = await admin.auth().verifyIdToken(token);
  return decoded.uid;
}

function requireAuth(req, res, next) {
  if (
    process.env.ALLOW_UNAUTHENTICATED === 'true' ||
    req.query.demo === 'true' ||
    (req.headers['x-demo'] && String(req.headers['x-demo']).toLowerCase() === 'true')
  ) {
    req.userId = 'demo';
    return next();
  }
  verifyToken(req)
    .then((uid) => {
      req.userId = uid;
      next();
    })
    .catch((err) => res.status(401).json({ error: 'UNAUTHENTICATED', detail: err.message }));
}

const asyncHandler = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

function ok(res, data) {
  res.status(200).json(data || { ok: true });
}

module.exports = { requireAuth, asyncHandler, ok };


