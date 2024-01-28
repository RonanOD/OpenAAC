-- Adding Vector Index to s4y_images as outlined in the "Indexing" section https://supabase.com/blog/openai-embeddings-postgres-vector

create index on s4y_images using ivfflat (embedding vector_cosine_ops)
with
  (lists = 100);
