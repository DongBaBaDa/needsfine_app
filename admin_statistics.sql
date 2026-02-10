-- [Admin Stats] SQL Functions for Business Intelligence
-- These functions aggregate data to provide actionable insights.

-- 1. Store Performance Metrics
-- Aggregates data by 'store_name' from posts (reviews).
-- Metrics: Review Count, Total Views, Total Likes (Helpful), Conversion Rate (Saves/Views)

CREATE OR REPLACE FUNCTION public.get_store_metrics()
RETURNS TABLE (
    store_name TEXT,
    review_count BIGINT,
    total_views BIGINT,
    total_likes BIGINT,
    save_count BIGINT,
    conversion_rate NUMERIC 
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH store_reviews AS (
        SELECT 
            p.store_name,
            COUNT(p.id) AS review_cnt,
            COALESCE(SUM(p.view_count), 0) AS view_sum
        FROM public.posts p
        WHERE p.store_name IS NOT NULL AND p.store_name != ''
        GROUP BY p.store_name
    ),
    store_likes AS (
        SELECT 
            p.store_name,
            COUNT(l.id) AS like_cnt
        FROM public.posts p
        JOIN public.post_likes l ON p.id = l.post_id
        GROUP BY p.store_name
    ),
    store_saves AS (
        SELECT 
            p.store_name,
            COUNT(s.id) AS save_cnt
        FROM public.posts p
        JOIN public.post_saves s ON p.id = s.post_id
        GROUP BY p.store_name
    )
    SELECT 
        sr.store_name,
        sr.review_cnt,
        sr.view_sum,
        COALESCE(sl.like_cnt, 0),
        COALESCE(ss.save_cnt, 0),
        CASE 
            WHEN sr.view_sum = 0 THEN 0
            ELSE ROUND((COALESCE(ss.save_cnt, 0)::numeric / sr.view_sum::numeric) * 100, 2)
        END
    FROM store_reviews sr
    LEFT JOIN store_likes sl ON sr.store_name = sl.store_name
    LEFT JOIN store_saves ss ON sr.store_name = ss.store_name
    ORDER BY sr.view_sum DESC;
END;
$$;

-- 2. Growth Metrics (Daily New Reviews)
-- Returns last 7 days of activity
CREATE OR REPLACE FUNCTION public.get_daily_growth_stats()
RETURNS TABLE (
    date DATE,
    new_reviews BIGINT,
    new_users BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH date_series AS (
        SELECT generate_series(CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE, '1 day')::date AS d
    )
    SELECT 
        ds.d AS date,
        COUNT(DISTINCT p.id) AS new_reviews,
        COUNT(DISTINCT u.id) AS new_users
    FROM 
        date_series ds
    LEFT JOIN public.posts p ON ds.d = p.created_at::date
    LEFT JOIN auth.users u ON ds.d = u.created_at::date
    GROUP BY 
        ds.d
    ORDER BY 
        ds.d ASC;
END;
$$;
