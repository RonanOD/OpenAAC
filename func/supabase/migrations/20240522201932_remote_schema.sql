set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.delete_storage_object(bucket text, object text, OUT status integer, OUT content text)
 RETURNS record
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$declare
  project_url text := 'https://bpcxexhrudktyrkkekne.supabase.co';
  service_role_key text := 'update-as-needed'; --  full access needed
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
end;$function$
;

create policy "Enable delete for users based on user_id"
on "public"."profiles"
as permissive
for delete
to public
using ((( SELECT auth.uid() AS uid) = id));


CREATE TRIGGER push_notifications AFTER INSERT ON public.notifications FOR EACH ROW EXECUTE FUNCTION supabase_functions.http_request('https://bpcxexhrudktyrkkekne.supabase.co/functions/v1/push', 'POST', '{"Content-type":"application/json"}', '{}', '1000');


