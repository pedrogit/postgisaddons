-------------------------------------------------------------------------------
-- PostGIS PL/pgSQL Add-ons - Test file for legacy functions
-- Version 1.35 for PostGIS 2.1.x and PostgreSQL 9.x
-- http://github.com/pedrogit/postgisaddons
--
-- This is free software; you can redistribute and/or modify it under
-- the terms of the GNU General Public Licence. See the COPYING file.
--
-- Copyright (C) 2013-2017 Pierre Racine <pierre.racine@sbf.ulaval.ca>.
--
-- This test file return a table of two columns: 
--
-- - the 1st column is the number of the test (e.g. 2.3) 
-- - the 2nd column is the name of the function being tested
-- - the 3rd column is the description of the test
-- - the 4th column is the result of the test: 
--
--   - true  if the test passed
--   - false if the test did not pass
--
-- Simply execute the text in as a SQL file to chech if every test pass.
--
-- Every series of test should include a test with:
--
--   - an empty geometry or an empty raster
--   - a null geometry or a null raster
--   - a no band raster
--
-----------------------------------------------------------     
---------------------------------------------------------
-- Test 7 - ST_SummaryStatsAgg
---------------------------------------------------------
UNION ALL
SELECT '7.1'::text number,
       'ST_SummaryStatsAgg'::text function_tested,
       'General test'::text description,
       ST_SummaryStatsAgg(rast)::text = '(200,9900,49.5,0,99)' passed
FROM (SELECT ST_CreateIndexRaster(ST_MakeEmptyRaster(10, 10, 0, 0, 1, 1, 0, 0), '8BUI') rast
      UNION ALL
      SELECT ST_CreateIndexRaster(ST_MakeEmptyRaster(10, 10, 10, 0, 1, 1, 0, 0), '8BUI')
     ) rt
---------------------------------------------------------
UNION ALL
SELECT '7.2'::text number,
       'ST_SummaryStatsAgg'::text function_tested,
       'Test with clipping'::text description,
       ST_SummaryStatsAgg(rast)::text = '(18,761,42.2777777777778,4,95)' passed
FROM (SELECT ST_Clip(rt.rast, ST_GeomFromEWKT('POLYGON((5 5, 15 7, 15 3, 5 5))'), 0.0) rast
      FROM (SELECT ST_CreateIndexRaster(ST_MakeEmptyRaster(10, 10, 0, 0, 1, 1, 0, 0), '8BUI') rast
            UNION ALL
            SELECT ST_CreateIndexRaster(ST_MakeEmptyRaster(10, 10, 10, 0, 1, 1, 0, 0), '8BUI')
           ) rt
     ) foo1
     