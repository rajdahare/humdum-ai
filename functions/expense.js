const admin = require('firebase-admin');
const { ok } = require('./utils');
const db = admin.firestore();

async function add(req, res) {
  const uid = req.userId;
  const { amount, category, note, imageUrl } = req.body || {};
  if (amount == null || !category) return res.status(400).json({ error: 'amount and category required' });
  const doc = await db.collection('users').doc(uid).collection('expenses').add({
    amount: Number(amount),
    category,
    note: note || null,
    imageUrl: imageUrl || null,
    createdAt: admin.firestore.FieldValue.serverTimestamp ? admin.firestore.FieldValue.serverTimestamp() : new Date(),
  });
  return ok(res, { id: doc.id });
}

async function computeMonthly(uid, year, month) {
  const start = new Date(year, month - 1, 1);
  const end = new Date(year, month, 1);
  const snap = await db
    .collection('users')
    .doc(uid)
    .collection('expenses')
    .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(start))
    .where('createdAt', '<', admin.firestore.Timestamp.fromDate(end))
    .get();
  let personal = 0,
    company = 0;
  for (const d of snap.docs) {
    const e = d.data();
    if (e.category === 'company') company += Number(e.amount || 0);
    else personal += Number(e.amount || 0);
  }
  return { personal, company, total: personal + company };
}

async function monthly(req, res) {
  const uid = req.userId;
  const { year, month } = req.query || {};
  const y = Number(year) || new Date().getFullYear();
  const m = Number(month) || new Date().getMonth() + 1;
  const totals = await computeMonthly(uid, y, m);
  return ok(res, totals);
}

module.exports = { add, monthly, computeMonthly };


