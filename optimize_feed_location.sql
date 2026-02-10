-- Add lat, lng columns to posts table for location-based features
ALTER TABLE public.posts 
ADD COLUMN IF NOT EXISTS lat DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS lng DOUBLE PRECISION;

-- Create index for faster geospatial queries (or simple box queries)
CREATE INDEX IF NOT EXISTS idx_posts_lat_lng ON public.posts (lat, lng);

-- Comment to explain
COMMENT ON COLUMN public.posts.lat IS 'Latitude (WGS84)';
COMMENT ON COLUMN public.posts.lng IS 'Longitude (WGS84)';

-- (Optional) If we wanted PostGIS in future, we would use geography type, 
-- but for now simple double is enough for "Near Me" box distance calculation.
