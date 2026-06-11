import { GoogleGenerativeAI } from 'npm:@google/generative-ai@0.21.0';
import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // ── Auth ──────────────────────────────────────────────────────────────────
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    // ── Parse ─────────────────────────────────────────────────────────────────
    const { audio, mimeType } = (await req.json()) as {
      audio: string; // base64-encoded audio bytes
      mimeType?: string;
    };

    if (!audio) {
      return new Response(
        JSON.stringify({ error: 'audio (base64) is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
      );
    }

    // ── API key check ─────────────────────────────────────────────────────────
    const apiKey = Deno.env.get('GEMINI_API_KEY');
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: 'GEMINI_API_KEY secret not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
      );
    }

    // ── Transcribe via Gemini (multimodal, audio input) ─────────────────────────
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: 'gemini-3.1-flash-lite',
      systemInstruction:
        'You are a speech transcription engine. Transcribe the spoken audio verbatim into clean, ' +
        'readable text with natural punctuation and capitalization. ' +
        'Detect the spoken language automatically and transcribe in that same language. ' +
        'Return ONLY the transcript text — no preamble, quotes, labels, or commentary. ' +
        'If the audio contains no intelligible speech, return an empty string.',
      generationConfig: { maxOutputTokens: 1024 },
    });

    const result = await model.generateContent([
      { inlineData: { mimeType: mimeType ?? 'audio/m4a', data: audio } },
      { text: 'Transcribe this voice memo.' },
    ]);
    const transcript = result.response.text().trim();

    return new Response(JSON.stringify({ transcript }), {
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });

  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error('transcribe-voice error:', message);
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
    );
  }
});
