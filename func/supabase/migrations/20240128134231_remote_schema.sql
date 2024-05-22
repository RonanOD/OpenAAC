
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";

CREATE SCHEMA IF NOT EXISTS "supabase_migrations";

ALTER SCHEMA "supabase_migrations" OWNER TO "postgres";

CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "vector" WITH SCHEMA "public";

CREATE OR REPLACE FUNCTION "public"."match_images"(query_embedding public.vector, match_threshold double precision, match_count integer) RETURNS TABLE(id bigint, content text, path text, similarity double precision)
    LANGUAGE "sql" STABLE
    AS $$
  select
    s4y_images.id,
    s4y_images.content,
    s4y_images.path,
    1 - (s4y_images.embedding <=> query_embedding) as similarity
  from s4y_images
  where s4y_images.embedding <=> query_embedding < 1 - match_threshold
  order by s4y_images.embedding <=> query_embedding
  limit match_count;
$$;

ALTER FUNCTION "public"."match_images"(query_embedding public.vector, match_threshold double precision, match_count integer) OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."s4y_images" (
    "id" bigint NOT NULL,
    "content" text,
    "path" text,
    "embedding" public.vector(1536)
);

ALTER TABLE "public"."s4y_images" OWNER TO "postgres";

CREATE SEQUENCE IF NOT EXISTS "public"."s4y_images_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "public"."s4y_images_id_seq" OWNER TO "postgres";

ALTER SEQUENCE "public"."s4y_images_id_seq" OWNED BY "public"."s4y_images"."id";

CREATE TABLE IF NOT EXISTS "supabase_migrations"."schema_migrations" (
    "version" text NOT NULL PRIMARY KEY,
    "statements" text[],
    "name" text
);

ALTER TABLE "supabase_migrations"."schema_migrations" OWNER TO "postgres";

ALTER TABLE ONLY "public"."s4y_images" ALTER COLUMN "id" SET DEFAULT nextval('public.s4y_images_id_seq'::regclass);

ALTER TABLE ONLY "public"."s4y_images"
    ADD CONSTRAINT "s4y_images_pkey" PRIMARY KEY ("id");

--ALTER TABLE ONLY "supabase_migrations"."schema_migrations"
--    ADD CONSTRAINT "schema_migrations_pkey" PRIMARY KEY ("version");

GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_in"(cstring, oid, integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_in"(cstring, oid, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_in"(cstring, oid, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_in"(cstring, oid, integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_out"(public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_out"(public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_out"(public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_out"(public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_recv"(internal, oid, integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_recv"(internal, oid, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_recv"(internal, oid, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_recv"(internal, oid, integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_send"(public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_send"(public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_send"(public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_send"(public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_typmod_in"(cstring[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_typmod_in"(cstring[]) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_typmod_in"(cstring[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_typmod_in"(cstring[]) TO "service_role";

GRANT ALL ON FUNCTION "public"."array_to_vector"(real[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_vector"(real[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_vector"(real[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_vector"(real[], integer, boolean) TO "service_role";

GRANT ALL ON FUNCTION "public"."array_to_vector"(double precision[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_vector"(double precision[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_vector"(double precision[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_vector"(double precision[], integer, boolean) TO "service_role";

GRANT ALL ON FUNCTION "public"."array_to_vector"(integer[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_vector"(integer[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_vector"(integer[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_vector"(integer[], integer, boolean) TO "service_role";

GRANT ALL ON FUNCTION "public"."array_to_vector"(numeric[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_vector"(numeric[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_vector"(numeric[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_vector"(numeric[], integer, boolean) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_to_float4"(public.vector, integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_to_float4"(public.vector, integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_to_float4"(public.vector, integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_to_float4"(public.vector, integer, boolean) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector"(public.vector, integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector"(public.vector, integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."vector"(public.vector, integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector"(public.vector, integer, boolean) TO "service_role";

GRANT ALL ON FUNCTION "public"."cosine_distance"(public.vector, public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."cosine_distance"(public.vector, public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."cosine_distance"(public.vector, public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."cosine_distance"(public.vector, public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."hnswhandler"(internal) TO "postgres";
GRANT ALL ON FUNCTION "public"."hnswhandler"(internal) TO "anon";
GRANT ALL ON FUNCTION "public"."hnswhandler"(internal) TO "authenticated";
GRANT ALL ON FUNCTION "public"."hnswhandler"(internal) TO "service_role";

GRANT ALL ON FUNCTION "public"."inner_product"(public.vector, public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."inner_product"(public.vector, public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."inner_product"(public.vector, public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."inner_product"(public.vector, public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."ivfflathandler"(internal) TO "postgres";
GRANT ALL ON FUNCTION "public"."ivfflathandler"(internal) TO "anon";
GRANT ALL ON FUNCTION "public"."ivfflathandler"(internal) TO "authenticated";
GRANT ALL ON FUNCTION "public"."ivfflathandler"(internal) TO "service_role";

GRANT ALL ON FUNCTION "public"."l1_distance"(public.vector, public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."l1_distance"(public.vector, public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."l1_distance"(public.vector, public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."l1_distance"(public.vector, public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."l2_distance"(public.vector, public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."l2_distance"(public.vector, public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."l2_distance"(public.vector, public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."l2_distance"(public.vector, public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."match_images"(query_embedding public.vector, match_threshold double precision, match_count integer) TO "anon";
GRANT ALL ON FUNCTION "public"."match_images"(query_embedding public.vector, match_threshold double precision, match_count integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."match_images"(query_embedding public.vector, match_threshold double precision, match_count integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_accum"(double precision[], public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_accum"(double precision[], public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_accum"(double precision[], public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_accum"(double precision[], public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_add"(public.vector, public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_add"(public.vector, public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_add"(public.vector, public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_add"(public.vector, public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_avg"(double precision[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_avg"(double precision[]) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_avg"(double precision[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_avg"(double precision[]) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_cmp"(public.vector, public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_cmp"(public.vector, public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_cmp"(public.vector, public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_cmp"(public.vector, public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_combine"(double precision[], double precision[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_combine"(double precision[], double precision[]) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_combine"(double precision[], double precision[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_combine"(double precision[], double precision[]) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_dims"(public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_dims"(public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_dims"(public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_dims"(public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_eq"(public.vector, public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_eq"(public.vector, public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_eq"(public.vector, public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_eq"(public.vector, public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_ge"(public.vector, public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_ge"(public.vector, public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_ge"(public.vector, public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_ge"(public.vector, public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_gt"(public.vector, public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_gt"(public.vector, public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_gt"(public.vector, public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_gt"(public.vector, public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_l2_squared_distance"(public.vector, public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_l2_squared_distance"(public.vector, public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_l2_squared_distance"(public.vector, public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_l2_squared_distance"(public.vector, public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_le"(public.vector, public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_le"(public.vector, public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_le"(public.vector, public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_le"(public.vector, public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_lt"(public.vector, public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_lt"(public.vector, public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_lt"(public.vector, public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_lt"(public.vector, public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_mul"(public.vector, public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_mul"(public.vector, public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_mul"(public.vector, public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_mul"(public.vector, public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_ne"(public.vector, public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_ne"(public.vector, public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_ne"(public.vector, public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_ne"(public.vector, public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_negative_inner_product"(public.vector, public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_negative_inner_product"(public.vector, public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_negative_inner_product"(public.vector, public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_negative_inner_product"(public.vector, public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_norm"(public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_norm"(public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_norm"(public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_norm"(public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_spherical_distance"(public.vector, public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_spherical_distance"(public.vector, public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_spherical_distance"(public.vector, public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_spherical_distance"(public.vector, public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."vector_sub"(public.vector, public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_sub"(public.vector, public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_sub"(public.vector, public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_sub"(public.vector, public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."avg"(public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."avg"(public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."avg"(public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."avg"(public.vector) TO "service_role";

GRANT ALL ON FUNCTION "public"."sum"(public.vector) TO "postgres";
GRANT ALL ON FUNCTION "public"."sum"(public.vector) TO "anon";
GRANT ALL ON FUNCTION "public"."sum"(public.vector) TO "authenticated";
GRANT ALL ON FUNCTION "public"."sum"(public.vector) TO "service_role";

GRANT ALL ON TABLE "public"."s4y_images" TO "anon";
GRANT ALL ON TABLE "public"."s4y_images" TO "authenticated";
GRANT ALL ON TABLE "public"."s4y_images" TO "service_role";

GRANT ALL ON SEQUENCE "public"."s4y_images_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."s4y_images_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."s4y_images_id_seq" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;
