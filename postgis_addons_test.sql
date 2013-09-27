-------------------------------------------------------------------------------
-- PostGIS PL/pgSQL Add-ons - Test file
-- Version 1.x for PostGIS 2.1.x and PostgreSQL 9.x
-- http://github.com/pedrogit/postgisaddons
--
-- This test file return a table of two columns: 
--
-- - the 1st column is the name of the function being tested
-- - the 2nd column is the number of the test (e.g. 2.3) 
-- - the 3nd column is the result of the test: 
--
--   - true if te test passed
--   - false if the test did not pass
-----------------------------------------------------------
-- Comment out the next line and the last of the file to display only failing tests
--SELECT * FROM (

---------------------------------------------------------
-- Test ST_DeleteBand

-- Test true deletion of one band
SELECT 'ST_DeleteBand'::text function_tested,
       '1.1'::text test_number,
        ST_NumBands(ST_DeleteBand(rast, 2)) = 1 passed
FROM (SELECT ST_AddBand(ST_MakeEmptyRaster(10, 10, 0, 0, 1),
                        ARRAY[ROW(NULL, '8BUI', 255, 0), 
                              ROW(NULL, '16BUI', 1, 2)]::addbandarg[]) rast
     ) foo
UNION ALL
-- Test index too high (3)
SELECT 'ST_DeleteBand'::text function_tested,
       '1.2'::text test_number,
        ST_NumBands(ST_DeleteBand(rast, 3)) = 2 passed
FROM (SELECT ST_AddBand(ST_MakeEmptyRaster(10, 10, 0, 0, 1),
                        ARRAY[ROW(NULL, '8BUI', 255, 0), 
                              ROW(NULL, '16BUI', 1, 2)]::addbandarg[]) rast
     ) foo
UNION ALL
-- Test index zero
SELECT 'ST_DeleteBand'::text function_tested,
       '1.3'::text test_number,
        ST_NumBands(ST_DeleteBand(rast, 0)) = 2 passed
FROM (SELECT ST_AddBand(ST_MakeEmptyRaster(10, 10, 0, 0, 1),
                        ARRAY[ROW(NULL, '8BUI', 255, 0), 
                              ROW(NULL, '16BUI', 1, 2)]::addbandarg[]) rast
     ) foo
UNION ALL
-- Test index minus one
SELECT 'ST_DeleteBand'::text function_tested,
       '1.4'::text test_number,
        ST_NumBands(ST_DeleteBand(rast, -1)) = 2 passed
FROM (SELECT ST_AddBand(ST_MakeEmptyRaster(10, 10, 0, 0, 1),
                        ARRAY[ROW(NULL, '8BUI', 255, 0), 
                              ROW(NULL, '16BUI', 1, 2)]::addbandarg[]) rast
     ) foo

---------------------------------------------------------
-- Insert new tests here

---------------------------------------------------------
-- This last line has to be commented out to display only failing test
--) foo WHERE NOT passed;