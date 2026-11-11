-- Hoist stable auth helpers out of per-row RLS expressions.
-- This preserves policy semantics while allowing PostgreSQL to evaluate the
-- auth values once per statement rather than once per candidate row.
do $$
declare
  policy_row record;
  next_qual text;
  next_check text;
  statement text;
begin
  for policy_row in
    select schemaname, tablename, policyname, qual, with_check
    from pg_policies
    where schemaname = 'public'
      and (
        coalesce(qual, '') ~ 'auth\.(uid|jwt|role)\(\)'
        or coalesce(with_check, '') ~ 'auth\.(uid|jwt|role)\(\)'
      )
  loop
    next_qual := policy_row.qual;
    next_check := policy_row.with_check;

    if next_qual is not null then
      next_qual := replace(next_qual, 'auth.uid()', '(select auth.uid())');
      next_qual := replace(next_qual, 'auth.jwt()', '(select auth.jwt())');
      next_qual := replace(next_qual, 'auth.role()', '(select auth.role())');
    end if;

    if next_check is not null then
      next_check := replace(next_check, 'auth.uid()', '(select auth.uid())');
      next_check := replace(next_check, 'auth.jwt()', '(select auth.jwt())');
      next_check := replace(next_check, 'auth.role()', '(select auth.role())');
    end if;

    statement := format(
      'alter policy %I on %I.%I',
      policy_row.policyname,
      policy_row.schemaname,
      policy_row.tablename
    );
    if next_qual is not null then
      statement := statement || format(' using (%s)', next_qual);
    end if;
    if next_check is not null then
      statement := statement || format(' with check (%s)', next_check);
    end if;
    execute statement;
  end loop;
end;
$$;
