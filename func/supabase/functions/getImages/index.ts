// Edge Function to return image paths for words

import OpenAI from 'https://deno.land/x/openai@v4.24.0/mod.ts'

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  // Search query is passed in request payload
  const { words } = await req.json()
  console.log("Get Images Call: " + words)

  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Init Supabase client
  const authHeader = req.headers.get('Authorization')!
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: authHeader } } }
  )

  // OpenAI recommends replacing newlines with spaces for best results
  const input = words.replace(/\n/g, ' ')

  // TODO: Load from Env
  // const apiKey = Deno.env.get('OPENAI_API_KEY')
  const apiKey = 'oopsie'
  const openai = new OpenAI({
    apiKey: apiKey,
  })

  // Generate embedding for the query itself
  const embeddingResponse = await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input,
  })

  if (embeddingResponse.data && embeddingResponse.data.length > 0) {
    const responseData = embeddingResponse.data[0]['embedding']
    const { data, error } = await supabaseClient.rpc('match_images', {
        match_count: 1, // Choose the number of matches
        match_threshold: 0.78, // Choose an appropriate threshold for your data
        query_embedding: responseData,
    })

    if (error != null) {
      return new Response(JSON.stringify(error), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500
      })
    } else {
      return new Response(JSON.stringify(data), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      })
    }
  } else {
    return new Response('ERROR: No embeddings returned', { status: 404, headers: corsHeaders })
  }
})

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/getImages' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
