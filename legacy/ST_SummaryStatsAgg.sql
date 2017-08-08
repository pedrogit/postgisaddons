-------------------------------------------------------------------------------
-- PostGIS PL/pgSQL Add-ons - Legacy function ST_SummaryStatsAgg()
-- Version 1.35 for PostGIS 2.1.x and PostgreSQL 9.x
-- http://github.com/pedrogit/postgisaddons
--
-- This is free software; you can redistribute and/or modify it under
-- the terms of the GNU General Public Licence. See the COPYING file.
--
-- Copyright (C) 2013-2017 Pierre Racine <pierre.racine@sbf.ulaval.ca>.
-- 
-------------------------------------------------------------------------------
-- ST_SummaryStatsAgg - Integrated in PostGIS in version 2.2.0
--
--   rast raster - Set of raster to be aggregated.
--
-- Aggregate function computing statistics on a series of rasters generally 
-- clipped by a geometry.
--
-- Statictics computed are:
--
--   - count  - Total number of pixels in the aggregate.
--   - sum    - Sum of all the pixel values in the aggregate.
--   - mean   - Mean value of all the pixel values in the aggregate.
--   - min    - Min value of all the pixel values in the aggregate.
--   - max    - Max value of all the pixel values in the aggregate.
--
-- This function is generally used to aggregate the pixel values of the numerous 
-- raster tiles clipped by a geometry. For large datasets, it should be faster than 
-- ST_Unioning the ST_Clipped raster pieces together before calling ST_SummaryStats.
-- One drawback of ST_SummaryStatsAgg over the ST_Union technique is that 
-- ST_SummaryStatsAgg can not compute the standard deviation (because computing stddev
-- require two passes over the pixel values).
--
-- Self contained example:
--
-- SELECT (ss).*
-- FROM (SELECT ST_SummaryStatsAgg(rast) ss
--       FROM (SELECT id, ST_Clip(rt.rast, gt.geom, 0.0) rast
--             FROM (SELECT ST_CreateIndexRaster(ST_MakeEmptyRaster(10, 10, 0, 0, 1, 1, 0, 0), '8BUI') rast
--                   UNION ALL
--                   SELECT ST_CreateIndexRaster(ST_MakeEmptyRaster(10, 10, 10, 0, 1, 1, 0, 0), '8BUI')
--                  ) rt, 
--                  (SELECT 'a'::text id, ST_GeomFromEWKT('POLYGON((5 5, 15 7, 15 3, 5 5))') geom
--                  ) gt
--             WHERE ST_Intersects(rt.rast, gt.geom)
--            ) foo1
--       GROUP BY id
--      ) foo2;
--
-- Typical exemple:
--
-- SELECT (ss).count, 
--        (ss).sum, 
--        (ss).mean, 
--        (ss).min, 
--        (ss).max
-- FROM (SELECT ST_SummaryStatsAgg(rast) ss
--       FROM (SELECT ST_Clip(rt.rast, gt.geom) rast -- ST_Clip assume there is a nodata value in the raster
--             FROM rasttable rt, geomtable gt
--             WHERE ST_Intersects(rt.rast, gt.geom)
--            ) foo
--       GROUP BY gt.id
--      ) foo2;
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 10/07/2013 v. 1.9
-----------------------------------------------------------

-----------------------------------------------------------
-- Type returned by the _ST_SummaryStatsAgg_StateFN state function
CREATE TYPE agg_summarystats AS 
(
    count bigint,
    sum double precision,
    mean double precision,
    min double precision,
    max double precision
);

-- ST_SummaryStatsAgg aggregate state function
CREATE OR REPLACE FUNCTION _ST_SummaryStatsAgg_StateFN(
    ss agg_summarystats, 
    rast raster, 
    nband int DEFAULT 1, 
    exclude_nodata_value boolean DEFAULT TRUE, 
    sample_percent double precision DEFAULT 1)
RETURNS agg_summarystats AS $$
    DECLARE
        newstats record;
        ret agg_summarystats;
    BEGIN
        IF rast IS NULL OR ST_HasNoBand(rast) OR ST_IsEmpty(rast) THEN
            RETURN ss;
        END IF;
        newstats := _ST_SummaryStats(rast, nband, exclude_nodata_value, sample_percent);
        IF $1 IS NULL THEN
            ret := (newstats.count,   -- count
                    newstats.sum,     -- sum
                    null,             -- future mean
                    newstats.min,     -- min
                    newstats.max      -- max
                   )::agg_summarystats;
        ELSE
            ret := (COALESCE(ss.count,0) + COALESCE(newstats.count, 0), -- count
                    COALESCE(ss.sum,0) + COALESCE(newstats.sum, 0),     -- sum
                    null,                                               -- future mean
                    least(ss.min, newstats.min),                        -- min
                    greatest(ss.max, newstats.max)                      -- max
                   )::agg_summarystats;      
        END IF;
--RAISE NOTICE 'min %', newstats.min;
        RETURN ret;
    END;
$$ LANGUAGE 'plpgsql';

-----------------------------------------------------------
-- ST_SummaryStatsAgg aggregate variant state function defaulting band 
-- number to 1, exclude_nodata_value to true and sample_percent to 1.
CREATE OR REPLACE FUNCTION _ST_SummaryStatsAgg_StateFN(
    ss agg_summarystats, 
    rast raster
)
RETURNS agg_summarystats AS $$
        SELECT _ST_SummaryStatsAgg_StateFN($1, $2, 1, true, 1);
$$ LANGUAGE 'sql';

-----------------------------------------------------------
-- ST_SummaryStatsAgg aggregate final function
CREATE OR REPLACE FUNCTION _ST_SummaryStatsAgg_FinalFN(
    ss agg_summarystats
)
RETURNS agg_summarystats AS $$
    DECLARE
        ret agg_summarystats;
    BEGIN
        ret := (($1).count,  -- count
                ($1).sum,    -- sum
                CASE WHEN ($1).count = 0 THEN null ELSE ($1).sum / ($1).count END,  -- mean
                ($1).min,    -- min
                ($1).max     -- max
               )::agg_summarystats;
        RETURN ret;
    END;
$$ LANGUAGE 'plpgsql';

-----------------------------------------------------------
-- ST_SummaryStatsAgg aggregate definition
CREATE AGGREGATE ST_SummaryStatsAgg(raster, int, boolean, double precision)
(
  SFUNC=_ST_SummaryStatsAgg_StateFN,
  STYPE=agg_summarystats,
  FINALFUNC=_ST_SummaryStatsAgg_FinalFN
);

-----------------------------------------------------------
-- ST_SummaryStatsAgg aggregate variant defaulting band number to 1, 
-- exclude_nodata_value to true and sample_percent to 1.
CREATE AGGREGATE ST_SummaryStatsAgg(raster)
(
  SFUNC=_ST_SummaryStatsAgg_StateFN,
  STYPE=agg_summarystats,
  FINALFUNC=_ST_SummaryStatsAgg_FinalFN
);
-------------------------------------------------------------------------------
