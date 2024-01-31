alter table "public"."s4y_images" enable row level security;

create policy "Enable read access for all users"
on "public"."s4y_images"
as permissive
for select
to authenticated
using (true);



