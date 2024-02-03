create extension if not exists "http" with schema "extensions";


set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.delete_avatar(avatar_url text, OUT status integer, OUT content text)
 RETURNS record
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
  select
      into status, content
           result.status, result.content
      from public.delete_storage_object('avatars', avatar_url) as result;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.delete_old_avatar()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  status int;
  content text;
  avatar_name text;
begin
  if coalesce(old.avatar_url, '') <> ''
      and (tg_op = 'DELETE' or (old.avatar_url <> coalesce(new.avatar_url, ''))) then
    -- extract avatar name
    avatar_name := old.avatar_url;
    select
      into status, content
      result.status, result.content
      from public.delete_avatar(avatar_name) as result;
    if status <> 200 then
      raise warning 'Could not delete avatar: % %', status, content;
    end if;
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.delete_old_profile()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
  delete from public.profiles where id = old.id;
  return old;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.delete_storage_object(bucket text, object text, OUT status integer, OUT content text)
 RETURNS record
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  project_url text := '<YOURPROJECTURL>';
  service_role_key text := '<YOURSERVICEROLEKEY>'; --  full access needed
  url text := project_url||'/storage/v1/object/'||bucket||'/'||object;
begin
  select
      into status, content
           result.status::int, result.content::text
      FROM extensions.http((
    'DELETE',
    url,
    ARRAY[extensions.http_header('authorization','Bearer '||service_role_key)],
    NULL,
    NULL)::extensions.http_request) as result;
end;
$function$
;

CREATE TRIGGER before_profile_changes BEFORE DELETE OR UPDATE OF avatar_url ON public.profiles FOR EACH ROW EXECUTE FUNCTION delete_old_avatar();


