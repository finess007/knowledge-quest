const { GoogleGenerativeAI } = require('@google/generative-ai');

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { videoUrl, videoId, title, channel } = req.body || {};
  if (!videoUrl && !videoId) return res.status(400).json({ error: 'Missing videoUrl or videoId' });

  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) return res.status(500).json({ error: 'GEMINI_API_KEY not configured' });

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });

    const ytUrl = videoUrl || `https://www.youtube.com/watch?v=${videoId}`;

    const prompt = `You are a video summarizer.${title ? ` Video: "${title}"` : ''}${channel ? ` by ${channel}` : ''}.

Provide:
1. A concise headline summary (1 sentence)
2. Key takeaways (5-8 bullet points)
3. Notable quotes or insights
4. Action items or implications

Keep it under 500 words.`;

    const result = await model.generateContent([
      { text: prompt },
      { fileData: { mimeType: 'video/*', fileUri: ytUrl } }
    ]);

    const summary = result.response.text();
    return res.status(200).json({ summary });
  } catch (err) {
    console.error('Summarize error:', err);
    return res.status(500).json({ error: err.message || 'Failed to generate summary' });
  }
};
