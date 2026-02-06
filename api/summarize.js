const { GoogleGenerativeAI } = require('@google/generative-ai');

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { videoUrl, videoId, transcript, title, channel } = req.body || {};

  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) return res.status(500).json({ error: 'GEMINI_API_KEY not configured' });

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });

    const prompt = `You are a video summarizer.${title ? ` Video: "${title}"` : ''}${channel ? ` by ${channel}` : ''}.

Provide:
1. A concise headline summary (1 sentence)
2. Key takeaways (5-8 bullet points)
3. Notable quotes or insights
4. Action items or implications

Keep it under 500 words.`;

    let result;

    // Method 1: Direct YouTube URL (Gemini native — best)
    const ytUrl = videoUrl || (videoId ? `https://www.youtube.com/watch?v=${videoId}` : null);
    if (ytUrl) {
      try {
        result = await model.generateContent([
          { text: prompt },
          { fileData: { mimeType: 'video/*', fileUri: ytUrl } }
        ]);
        const summary = result.response.text();
        if (summary && summary.length > 50) {
          return res.status(200).json({ summary, method: 'youtube-native' });
        }
      } catch (ytErr) {
        console.warn('YouTube native failed, trying transcript fallback:', ytErr.message);
      }
    }

    // Method 2: Transcript fallback
    if (!transcript) {
      return res.status(400).json({ error: 'Could not access video. No transcript provided as fallback.' });
    }

    const maxChars = 100000;
    const text = transcript.length > maxChars ? transcript.substring(0, maxChars) + '\n[truncated]' : transcript;

    result = await model.generateContent(prompt + `\n\nTRANSCRIPT:\n${text}`);
    const summary = result.response.text();

    return res.status(200).json({ summary, method: 'transcript' });
  } catch (err) {
    console.error('Summarize error:', err);
    return res.status(500).json({ error: err.message || 'Failed to generate summary' });
  }
};
