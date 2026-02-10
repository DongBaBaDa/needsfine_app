-- Integer ID를 가진 테이블(posts 등)을 위한 조회수 증가 함수
CREATE OR REPLACE FUNCTION public.increment_counter_int(table_name text, column_name text, row_id int)
RETURNS void AS $$
BEGIN
    EXECUTE format('UPDATE public.%I SET %I = COALESCE(%I, 0) + 1 WHERE id = $1', table_name, column_name, column_name)
    USING row_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.decrement_counter_int(table_name text, column_name text, row_id int)
RETURNS void AS $$
BEGIN
    EXECUTE format('UPDATE public.%I SET %I = GREATEST(COALESCE(%I, 0) - 1, 0) WHERE id = $1', table_name, column_name, column_name)
    USING row_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.increment_counter_int(text, text, int) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.decrement_counter_int(text, text, int) TO anon, authenticated, service_role;
