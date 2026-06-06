import OpenAI from 'npm:openai@4.52.0';
import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface DiaryEvent {
  type: 'stamp' | 'checkin' | 'note';
  time: string;       // "HH:mm"
  place?: string;
  caption?: string;
  note?: string;
  tags?: string[];
  photos: string[];   // base64 JPEG strings (resized client-side to ≤512 px)
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // ── Auth check ──────────────────────────────────────────────────
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

  // ── Parse request ───────────────────────────────────────────────
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

  // ── Build prompt ────────────────────────────────────────────────
  let activityText = `Date: ${date}\n\nActivities (chronological):\n`;

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
  }

  // ── Collect photos (max 5, already resized to ≤512 px base64) ──
  const imageContent: OpenAI.Chat.ChatCompletionContentPart[] = [];
  let photoCount = 0;
  for (const event of events) {
    for (const b64 of event.photos) {
      if (photoCount >= 5) break;
      imageContent.push({
        type: 'image_url',
        image_url: {
          url: `data:image/jpeg;base64,${b64}`,
          detail: 'low', // 85 tokens flat — keeps cost minimal
        },
      });
      photoCount++;
    }
    if (photoCount >= 5) break;
  }

  // ── Call GPT-4o mini ────────────────────────────────────────────
  const openai = new OpenAI({ apiKey: Deno.env.get('OPENAI_API_KEY') });

  const userContent: OpenAI.Chat.ChatCompletionContentPart[] = [
    { type: 'text', text: activityText },
    ...imageContent,
  ];

  const completion = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    max_tokens: 600,
    messages: [
      {
        role: 'system',
        content:
          'You are a personal diary writing assistant. Given a list of activities and optional photos from the user\'s day, write a warm, reflective first-person diary entry. ' +
          'Write 2–4 paragraphs. Be specific about what they experienced — use details from the photos and activity descriptions. ' +
          'Do not list events mechanically. Do not start with "Dear Diary". Write in a natural, personal voice.',
      },
      { role: 'user', content: userContent },
    ],
  });

  const diary = completion.choices[0]?.message?.content?.trim() ?? '';

  return new Response(JSON.stringify({ diary }), {
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  });
});
