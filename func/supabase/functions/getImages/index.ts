// Edge Function to return image path for words matched by vector embedding

import OpenAI from 'https://deno.land/x/openai@v4.24.0/mod.ts'

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const openAIEmbeddingsModel = 'text-embedding-3-small'
const vectorMatchThreshold  = 0.78

Deno.serve(async (req) => {
  // Search query is passed in request payload
  const { words } = await req.json()
  console.log("Get Images Call: " + words)

  // Handle CORS if call is from Browser
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try{
    // Init Supabase client with the Auth context of the logged in user
    const authHeader = req.headers.get('Authorization')!
    
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    // Now we can get the session or user object
    const {
      data: { user, error },
    } = await supabaseClient.auth.getUser()

    //const { data, error } = await supabaseClient.from('profiles').select('*')
    if (error) throw error

    var grantedAccess = false
    if (user['user_metadata'] != null && user['user_metadata']['can_access'] != null) {
      grantedAccess = user['user_metadata']['can_access']
    }

    // Gate only users with learningo emails or explicit access
    if (!(user['email'].endsWith("@learningo.org") || grantedAccess)) {
      console.log("Unauthorized user: " + JSON.stringify(user))
      return new Response(JSON.stringify({ error: "Not allowed" }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }

    // OpenAI recommends replacing newlines with spaces for best results
    const input = words.replace(/\n/g, ' ')

    const apiKey = Deno.env.get('OPENAI_API_KEY')
    const openai = new OpenAI({
      apiKey: apiKey,
    })

    // Generate embedding for the query itself
    const embeddingResponse = await openai.embeddings.create({
      model: openAIEmbeddingsModel,
      input,
    })

    if (embeddingResponse.data && embeddingResponse.data.length > 0) {
      const responseData = embeddingResponse.data[0]['embedding']
      const { data, error } = await supabaseClient.rpc('match_images', {
          match_count: 1, // Choose the number of matches
          match_threshold: vectorMatchThreshold, // Choose an appropriate threshold for your data
          query_embedding: responseData,
      })

      if (error != null) {
        console.log("Error matching images: " + JSON.stringify(error))
        return new Response(JSON.stringify(error), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 500
        })
      } else {
        // TODO: Figure out why this doesn't work. We can remove auth perm to images if get working
        // Create a signed URL of the private image
        /*if (data.length == 1) {
          const path = data[0]['path']
          console.log("PATH: " + path)
          signImage(path)
        }*/
        console.log("Successful processing for " + user['email'])
        return new Response(JSON.stringify(data), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200
        })
      }
    } else {
      return new Response('ERROR: No embeddings returned', { status: 404, headers: corsHeaders })
    }
  } catch (error) {
    console.log("ERR: " + error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
/*
function signImage(path) {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    {auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    }
  );

  const { data, error } = supabase.storage
  .from('images')
  .createSignedUrl(path, 3600)

  console.log("XXX data: " + JSON.stringify(data) + " err " + JSON.stringify(error))
}
*/
