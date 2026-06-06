import { GoogleGenerativeAI } from 'npm:@google/generative-ai@0.21.0';
import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface DiaryEvent {
  type: 'stamp' | 'checkin' | 'note';
  time: string;
  place?: string;
  caption?: string;
  note?: string;
  tags?: string[];
  photos: string[];
}

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
    const { date, events } = (await req.json()) as {
      date: string;
      events: DiaryEvent[];
    };

    if (!date || !Array.isArray(events) || events.length === 0) {
      return new Response(
        JSON.stringify({ error: 'date and events are required' }),
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

    // ── Build prompt parts ────────────────────────────────────────────────────
    let activityText = `Date: ${date}\n\nActivities (chronological):\n`;
    let photoCount = 0;
    // deno-lint-ignore no-explicit-any
    const parts: any[] = [];

    for (const event of events) {
      if (event.type === 'note') {
        activityText += `  ${event.time} — Note: "${event.note}"\n`;
      } else if (event.type === 'stamp') {
        activityText += `  ${event.time} — Visited ${event.place}`;
        if (event.caption) activityText += `, shared: "${event.caption}"`;
        if (event.tags?.length) activityText += ` [${event.tags.join(', ')}]`;
        activityText += '\n';
      } else {
        activityText += `  ${event.time} — Checked in at ${event.place}`;
        if (event.note) activityText += `: "${event.note}"`;
        activityText += '\n';
      }
      for (const b64 of (event.photos ?? [])) {
        if (photoCount >= 5) break;
        parts.push({ inlineData: { mimeType: 'image/jpeg', data: b64 } });
        photoCount++;
      }
    }

    // Text part goes first, images follow
    parts.unshift({ text: activityText });

    // ── Call Gemini 2.0 Flash Lite ────────────────────────────────────────────
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: 'gemini-2.0-flash-lite',
      systemInstruction:
        "You are a personal diary writing assistant. Given a list of activities and optional photos from the user's day, " +
        'write a warm, reflective first-person diary entry. Write 2–4 paragraphs. ' +
        'Be specific about what they experienced — use details from the photos and activity descriptions. ' +
        'Do not list events mechanically. Do not start with "Dear Diary". Write in a natural, personal voice.',
      generationConfig: { maxOutputTokens: 600 },
    });

    const result = await model.generateContent(parts);
    const diary = result.response.text().trim();

    return new Response(JSON.stringify({ diary }), {
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });

  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error('generate-diary error:', message);
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
    );
  }
});
