const express = require('express');
const bodyParser = require('body-parser');
const DOMPurify = require('isomorphic-dompurify');
const app = express();
const port = 3000;

let comments = [];

app.use(express.static('public'));
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

app.get('/search', (req, res) => {
  const query = req.query.q || '';
  const mode = req.query.mode || 'secure';

  const output = mode === 'vulnerable'
    ? `<p>❌ Reflected: ${query}</p>`
    : `<p>✅ Reflected (sanitized): ${DOMPurify.sanitize(query)}</p>`;

  res.send(`<html><body>${output}<br><a href="/">Back</a></body></html>`);
});

app.post('/comment', (req, res) => {
  const { comment, mode } = req.body;

  const stored = mode === 'vulnerable' ? comment : DOMPurify.sanitize(comment);
  comments.push(stored);

  const output = comments.map((c, i) => `<p>${i + 1}. ${c}</p>`).join('');
  res.send(`<html><body><h3>Stored Comments</h3>${output}<br><a href="/">Back</a></body></html>`);
});

app.listen(port, () => {
  console.log(`🧪 XSS Lab running at http://localhost:${port}`);
});
