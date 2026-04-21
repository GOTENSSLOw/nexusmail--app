const API_BASE = '/api';

export async function registerUser(username, password) {
  const res = await fetch(`${API_BASE}/register/`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  });
  if (!res.ok) {
    const err = await res.json();
    throw new Error(err.error || 'Registration failed');
  }
  return await res.json();
}

export async function loginUser(username, password) {
  const res = await fetch(`${API_BASE}/read-emails/${encodeURIComponent(username)}/`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ password }),
  });
  if (!res.ok) {
    const err = await res.json();
    throw new Error(err.error || 'Login failed');
  }
  return await res.json();
}

export async function fetchEmails(username, password) {
  const res = await fetch(`${API_BASE}/read-emails/${encodeURIComponent(username)}/`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ password }),
  });
  if (!res.ok) throw new Error('Failed to fetch emails');
  return await res.json();
}

export async function sendEmail(sender, to, subject, body) {
  const res = await fetch(`${API_BASE}/send-email/`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ sender, to, subject, body }),
  });
  if (!res.ok) {
    const err = await res.json();
    throw new Error(err.error || 'Failed to send email');
  }
  return await res.json();
}
