create policy "Allow authenticated download 1ffg0oo_0"
on "storage"."objects"
as permissive
for select
to authenticated, service_role
using ((bucket_id = 'images'::text));



