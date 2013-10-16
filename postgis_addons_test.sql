-------------------------------------------------------------------------------
-- PostGIS PL/pgSQL Add-ons - Test file
-- Version 1.12 for PostGIS 2.1.x and PostgreSQL 9.x
-- http://github.com/pedrogit/postgisaddons
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
-- Table necessary to test ST_AddUniqueID
DROP TABLE IF EXISTS public.test_adduniqueid;
CREATE TABLE public.test_adduniqueid AS
SELECT * FROM (VALUES ('one'), ('two'), ('three')) AS t (column1);

SELECT ST_AddUniqueID('public', 'test_adduniqueid', 'column2');

-----------------------------------------------------------
-- Table necessary to test ST_ExtractToRaster
DROP TABLE IF EXISTS test_extracttoraster;
CREATE TABLE test_extracttoraster AS
SELECT 'a'::text id, 1 val, ST_GeomFromText('POLYGON((0 1, 10 2, 10 0, 0 1))') geom
UNION ALL
SELECT 'b'::text, 3, ST_GeomFromText('POLYGON((10 1, 0 2, 0 0, 10 1))')
UNION ALL
SELECT 'c'::text, 1, ST_GeomFromText('POLYGON((1 0, 1 2, 4 2, 4 0, 1 0))')
UNION ALL
SELECT 'd'::text, 6, ST_GeomFromText('POLYGON((7 0, 7 2, 8 2, 8 0, 7 0))')
UNION ALL
SELECT 'e'::text, 5, ST_GeomFromText('LINESTRING(0 0, 10 2)')
UNION ALL
SELECT 'f'::text, 6, ST_GeomFromText('LINESTRING(4 0, 6 2)')
UNION ALL
SELECT 'g'::text, 7, ST_GeomFromText('POINT(4 1.5)')
UNION ALL
SELECT 'h'::text, 8, ST_GeomFromText('POINT(8 0.5)')
UNION ALL
SELECT 'i'::text, 9, ST_GeomFromText('MULTIPOINT(6 0.5, 7 0.6)');

-----------------------------------------------------------
-- Table necessary to test ST_GlobalRasterUnion
DROP TABLE IF EXISTS test_globalrasterunion;
CREATE TABLE test_globalrasterunion AS
SELECT 1 rid, ST_CreateIndexRaster(ST_MakeEmptyRaster(5, 5, 0, 0, 1, 1, 0, 0), '8BSI') rast
UNION ALL
SELECT 2, ST_CreateIndexRaster(ST_MakeEmptyRaster(6, 5, 2.8, 2.8, 0.85, 0.85, 0, 0), '8BSI');

-----------------------------------------------------------
-- Comment out the following line and the last one of the file to display 
-- only failing tests
--SELECT * FROM (

---------------------------------------------------------
-- Test 1 - ST_DeleteBand
---------------------------------------------------------

SELECT '1.1'::text number,
       'ST_DeleteBand'::text function_tested,
       'True deletion of one band'::text description,
        ST_NumBands(ST_DeleteBand(ST_AddBand(ST_MakeEmptyRaster(10, 10, 0, 0, 1),
                                             ARRAY[ROW(NULL, '8BUI', 255, 0), 
                                                   ROW(NULL, '16BUI', 1, 2)]::addbandarg[]), 2)) = 1 passed
---------------------------------------------------------
UNION ALL
SELECT '1.2'::text number,
       'ST_DeleteBand'::text function_tested,
       'Index too high (3)'::text description,
        ST_NumBands(ST_DeleteBand(rast, 3)) = 2 passed
FROM (SELECT ST_AddBand(ST_MakeEmptyRaster(10, 10, 0, 0, 1),
                        ARRAY[ROW(NULL, '8BUI', 255, 0), 
                              ROW(NULL, '16BUI', 1, 2)]::addbandarg[]) rast
     ) foo
---------------------------------------------------------
UNION ALL
SELECT '1.3'::text number,
       'ST_DeleteBand'::text function_tested,
       'Index zero'::text description,
        ST_NumBands(ST_DeleteBand(rast, 0)) = 2 passed
FROM (SELECT ST_AddBand(ST_MakeEmptyRaster(10, 10, 0, 0, 1),
                        ARRAY[ROW(NULL, '8BUI', 255, 0), 
                              ROW(NULL, '16BUI', 1, 2)]::addbandarg[]) rast
     ) foo
---------------------------------------------------------
UNION ALL
SELECT '1.4'::text number,
       'ST_DeleteBand'::text function_tested,
       'Index minus one'::text description,
        ST_NumBands(ST_DeleteBand(rast, -1)) = 2 passed
FROM (SELECT ST_AddBand(ST_MakeEmptyRaster(10, 10, 0, 0, 1),
                        ARRAY[ROW(NULL, '8BUI', 255, 0), 
                              ROW(NULL, '16BUI', 1, 2)]::addbandarg[]) rast
     ) foo
---------------------------------------------------------
UNION ALL
SELECT '1.5'::text number,
       'ST_DeleteBand'::text function_tested,
       'Null raster'::text description,
        ST_DeleteBand(null, 2) IS NULL passed
---------------------------------------------------------
UNION ALL
SELECT '1.6'::text number,
       'ST_DeleteBand'::text function_tested,
       'No band raster'::text description,
        ST_HasNoBand(ST_DeleteBand(ST_MakeEmptyRaster(10, 10, 0, 0, 1), -1)) passed
---------------------------------------------------------
UNION ALL
SELECT '1.7'::text number,
       'ST_DeleteBand'::text function_tested,
       'Empty raster'::text description,
        ST_IsEmpty(ST_DeleteBand(ST_MakeEmptyRaster(0, 0, 0, 0, 1), -1)) passed
---------------------------------------------------------
UNION ALL
SELECT '1.8'::text number,
       'ST_DeleteBand'::text function_tested,
       'Test null band parameter'::text description,
        ST_NumBands(ST_DeleteBand(rast, null)) = 2 passed
FROM (SELECT ST_AddBand(ST_MakeEmptyRaster(10, 10, 0, 0, 1),
                        ARRAY[ROW(NULL, '8BUI', 255, 0), 
                              ROW(NULL, '16BUI', 1, 2)]::addbandarg[]) rast
     ) foo

---------------------------------------------------------
-- Test 2 - ST_CreateIndexRaster
---------------------------------------------------------

UNION ALL
SELECT '2.1'::text number,
       'ST_CreateIndexRaster'::text function_tested,
       'Basic index raster'::text description,
       (ST_DumpValues(
            ST_CreateIndexRaster(
                ST_MakeEmptyRaster(4, 4, 0, 0, 1, 1, 0, 0), '8BUI'))).valarray = 
       '{{0,4,8,12},{1,5,9,13},{2,6,10,14},{3,7,11,15}}' passed
---------------------------------------------------------
UNION ALL
SELECT '2.2'::text number,
       'ST_CreateIndexRaster'::text function_tested,
       'Pixel type 8BUI'::text description,
       ST_BandPixelType(
           ST_CreateIndexRaster(
               ST_MakeEmptyRaster(4, 4, 0, 0, 1, 1, 0, 0), '8BUI')) = 
       '8BUI' passed
---------------------------------------------------------
UNION ALL
SELECT '2.3'::text number,
       'ST_CreateIndexRaster'::text function_tested,
       'Pixel type 32BF'::text description,
       ST_BandPixelType(
           ST_CreateIndexRaster(
               ST_MakeEmptyRaster(4, 4, 0, 0, 1, 1, 0, 0), '32BF')) = 
       '32BF' passed
---------------------------------------------------------
UNION ALL
SELECT '2.4'::text number,
       'ST_CreateIndexRaster'::text function_tested,
       'Start value = 99'::text description,
       (ST_DumpValues(
           ST_CreateIndexRaster(
               ST_MakeEmptyRaster(4, 4, 0, 0, 1, 1, 0, 0), '8BUI', 99))).valarray = 
       '{{99,103,107,111},{100,104,108,112},{101,105,109,113},{102,106,110,114}}' passed
---------------------------------------------------------
UNION ALL
SELECT '2.5'::text number,
       'ST_CreateIndexRaster'::text function_tested,
       'Negative start value = -99'::text description,
       (ST_DumpValues(
           ST_CreateIndexRaster(
               ST_MakeEmptyRaster(4, 4, 0, 0, 1, 1, 0, 0), '8BSI', -99))).valarray = 
       '{{-99,-95,-91,-87},{-98,-94,-90,-86},{-97,-93,-89,-85},{-96,-92,-88,-84}}' passed
---------------------------------------------------------
UNION ALL
SELECT '2.6'::text number,
       'ST_CreateIndexRaster'::text function_tested,
       'Decrementing X'::text description,
       (ST_DumpValues(
           ST_CreateIndexRaster(
               ST_MakeEmptyRaster(4, 4, 0, 0, 1, 1, 0, 0), '8BUI', 0, false))).valarray = 
       '{{12,8,4,0},{13,9,5,1},{14,10,6,2},{15,11,7,3}}' passed
---------------------------------------------------------
UNION ALL
SELECT '2.7'::text number,
       'ST_CreateIndexRaster'::text function_tested,
       'Decrementing X and Y'::text description,
       (ST_DumpValues(
           ST_CreateIndexRaster(
               ST_MakeEmptyRaster(4, 4, 0, 0, 1, 1, 0, 0), '8BUI', 0, false, false))).valarray = 
       '{{15,11,7,3},{14,10,6,2},{13,9,5,1},{12,8,4,0}}' passed
---------------------------------------------------------
UNION ALL
SELECT '2.8'::text number,
       'ST_CreateIndexRaster'::text function_tested,
       'Rows increment first'::text description,
       (ST_DumpValues(
           ST_CreateIndexRaster(
               ST_MakeEmptyRaster(4, 4, 0, 0, 1, 1, 0, 0), '8BUI', 0, true, true, false))).valarray = 
       '{{0,1,2,3},{4,5,6,7},{8,9,10,11},{12,13,14,15}}' passed
---------------------------------------------------------
UNION ALL
SELECT '2.9'::text number,
       'ST_CreateIndexRaster'::text function_tested,
       'Rows increment first and row-prime scan order'::text description,
       (ST_DumpValues(
           ST_CreateIndexRaster(
               ST_MakeEmptyRaster(4, 4, 0, 0, 1, 1, 0, 0), '8BUI', 0, true, true, false, false))).valarray = 
       '{{0,1,2,3},{7,6,5,4},{8,9,10,11},{15,14,13,12}}' passed
---------------------------------------------------------
UNION ALL
SELECT '2.10'::text number,
       'ST_CreateIndexRaster'::text function_tested,
       'Rows incremant by 2 and cols by 10'::text description,
       (ST_DumpValues(
           ST_CreateIndexRaster(
               ST_MakeEmptyRaster(4, 4, 0, 0, 1, 1, 0, 0), '8BUI', 0, true, true, true, true, 10, 2))).valarray = 
       '{{0,10,20,30},{2,12,22,32},{4,14,24,34},{6,16,26,36}}' passed
---------------------------------------------------------
UNION ALL
SELECT '2.11'::text number,
       'ST_CreateIndexRaster'::text function_tested,
       'Start at 3, decrement with y, row-prime scan order, increment by 100 and 2'::text description,
       (ST_DumpValues(
           ST_CreateIndexRaster(
               ST_MakeEmptyRaster(4, 4, 0, 0, 1, 1, 0, 0), '8BUI', 3, true, false, true, false, 100, 2))).valarray = 
       '{{9,103,209,255},{7,105,207,255},{5,107,205,255},{3,109,203,255}}' passed
---------------------------------------------------------
UNION ALL
SELECT '2.12'::text number,
       'ST_CreateIndexRaster'::text function_tested,
       'Start at -10, decrement with x, columns increment first, increment by 2 and 20'::text description,
       (ST_DumpValues(
           ST_CreateIndexRaster(
               ST_MakeEmptyRaster(4, 4, 0, 0, 1, 1, 0, 0), '8BSI', -10, false, true, false, true, 2, 20))).valarray = 
       '{{-4,-6,-8,-10},{16,14,12,10},{36,34,32,30},{56,54,52,50}}' passed
---------------------------------------------------------
UNION ALL
SELECT '2.13'::text number,
       'ST_CreateIndexRaster'::text function_tested,
       'Start at -10, decrement with x and y, columns increment first, row-prime scan order, increment by 2 and 20'::text description,
       (ST_DumpValues(
           ST_CreateIndexRaster(
               ST_MakeEmptyRaster(4, 4, 0, 0, 1, 1, 0, 0), '8BSI', -10, false, false, false, false, 2, 20))).valarray = 
       '{{50,52,54,56},{36,34,32,30},{10,12,14,16},{-4,-6,-8,-10}}' passed
---------------------------------------------------------
UNION ALL
SELECT '2.14'::text number,
       'ST_CreateIndexRaster'::text function_tested,
       'Null raster'::text description,
       ST_CreateIndexRaster(null, '8BSI', -10, false, false, false, false, 2, 20) IS NULL  passed
---------------------------------------------------------
UNION ALL
SELECT '2.15'::text number,
       'ST_CreateIndexRaster'::text function_tested,
       'Empty raster'::text description,
       ST_IsEmpty(ST_CreateIndexRaster(
                ST_MakeEmptyRaster(0, 4, 0, 0, 1, 1, 0, 0), 
                '8BSI', -10, false, false, false, false, 2, 20)) passed

---------------------------------------------------------
-- Test 3 - ST_RandomPoints
---------------------------------------------------------

UNION ALL
SELECT '3.1'::text number,
        'ST_RandomPoints'::text function_tested,
        'Ten points in a specific geometry'::text description,
        ST_Union(geom) = '01040000000A00000001010000000000D2468A2952C000008AB267264840010100000000009839B00052C00000DEFEB8DF474001010000000000A8D450F251C00000B8AE47BF474001010000000000F2F586EA51C000009A5F44F5474001010000000000A62203E551C0000058645BAF474001010000000000DA54DDB551C000003AE14DC2474001010000000000928331B351C00000188999CB474001010000000000C6B5887551C00000461E55E24740010100000000009C962F6951C00000EC7BE05148400101000000000076852F6251C00000580F41FE4740'::geometry passed
FROM (SELECT ST_RandomPoints(ST_GeomFromText('POLYGON((-73 48,-72 49,-71 48,-69 49,-69 48,-71 47,-73 48))'), 10, 0.5) geom) foo
---------------------------------------------------------
UNION ALL
SELECT '3.2'::text number,
        'ST_RandomPoints'::text function_tested,
        'Null geometry'::text description,
        ST_RandomPoints(null, 10, 0.5) IS NULL passed
---------------------------------------------------------
UNION ALL
SELECT '3.3'::text number,
        'ST_RandomPoints'::text function_tested,
        'Empty geometry'::text description,
        ST_RandomPoints(ST_GeomFromText('GEOMETRYCOLLECTION EMPTY'), 10, 0.5) IS NULL passed

---------------------------------------------------------
-- Test 4 - ST_ColumnExists
---------------------------------------------------------

UNION ALL
SELECT '4.1'::text number,
       'ST_ColumnExists'::text function_tested,
       'Simple test'::text description,
       ST_ColumnExists('public', 'test_adduniqueid', 'column1') passed
---------------------------------------------------------
UNION ALL
SELECT '4.2'::text number,
       'ST_ColumnExists'::text function_tested,
       'Simple negative test'::text description,
       NOT ST_ColumnExists('public', 'test_adduniqueid', 'column1crap') passed
---------------------------------------------------------
UNION ALL
SELECT '4.3'::text number,
       'ST_ColumnExists'::text function_tested,
       'Default schema variant'::text description,
       ST_ColumnExists('test_adduniqueid', 'column1') passed

---------------------------------------------------------
-- Test 5 - ST_AddUniqueID
---------------------------------------------------------

UNION ALL
SELECT '5.1'::text number,
       'ST_AddUniqueID'::text function_tested,
       'Use ST_ColumnExists to check if column2 was correctly added above'::text description,
       ST_ColumnExists('public', 'test_adduniqueid', 'column2') passed
---------------------------------------------------------
UNION ALL
SELECT '5.2'::text number,
       'ST_AddUniqueID'::text function_tested,
       'Test replacement of existing column2'::text description,
       ST_AddUniqueID('public', 'test_adduniqueid', 'column2', true) passed
---------------------------------------------------------
UNION ALL
SELECT '5.3'::text number,
       'ST_AddUniqueID'::text function_tested,
       'Test variant defaulting to public schema'::text description,
       ST_AddUniqueID('public', 'test_adduniqueid', 'column2', true) passed

---------------------------------------------------------
-- Test 6 - ST_AreaWeightedSummaryStats
---------------------------------------------------------
UNION ALL
SELECT '6.1'::text number,
       'ST_AreaWeightedSummaryStats'::text function_tested,
       'General test'::text description,
       array_agg(aws)::text = '{"(4,2,0103000000010000000B0000000000000000002440000000000000000000000000000024400000000000000040000000000000244000000000000008400000000000002440000000000000104000000000000024400000000000001440000000000000284000000000000014400000000000002840000000000000104000000000000028400000000000000840000000000000284000000000000000400000000000002840000000000000000000000000000024400000000000000000,10,2.5,26,6.5,28,2.8,4,2,2,4,10,2.5,4,2)","(2,2,01060000000200000001030000000100000005000000000000000000000000000000000000000000000000000000000000000000244000000000000024400000000000002440000000000000244000000000000000000000000000000000000000000000000001030000000100000005000000000000000000284000000000000000000000000000002840000000000000F03F0000000000002A40000000000000F03F0000000000002A40000000000000000000000000000028400000000000000000,101,50.5,44,22,10001,99.019801980198,100,1,100,1,101,50.5,100,1)"}' passed
FROM (SELECT ST_AreaWeightedSummaryStats((geom, val)::geomval) as aws, id
      FROM (SELECT ST_GeomFromEWKT('POLYGON((0 0,0 10, 10 10, 10 0, 0 0))') as geom, 'a' as id, 100 as val
            UNION ALL
            SELECT ST_GeomFromEWKT('POLYGON((12 0,12 1, 13 1, 13 0, 12 0))') as geom, 'a' as id, 1 as val
            UNION ALL
            SELECT ST_GeomFromEWKT('POLYGON((10 0, 10 2, 12 2, 12 0, 10 0))') as geom, 'b' as id, 4 as val
            UNION ALL
            SELECT ST_GeomFromEWKT('POLYGON((10 2, 10 3, 12 3, 12 2, 10 2))') as geom, 'b' as id, 2 as val
            UNION ALL
            SELECT ST_GeomFromEWKT('POLYGON((10 3, 10 4, 12 4, 12 3, 10 3))') as geom, 'b' as id, 2 as val
            UNION ALL
            SELECT ST_GeomFromEWKT('POLYGON((10 4, 10 5, 12 5, 12 4, 10 4))') as geom, 'b' as id, 2 as val
           ) foo1
      GROUP BY id
     ) foo2
---------------------------------------------------------
UNION ALL
SELECT '6.2'::text number,
       'ST_AreaWeightedSummaryStats'::text function_tested,
       'Test for null and empty geometry'::text description,
       array_agg(aws)::text = '{"(2,1,0103000000010000000700000000000000000024400000000000000000000000000000244000000000000000400000000000002440000000000000084000000000000028400000000000000840000000000000284000000000000000400000000000002840000000000000000000000000000024400000000000000000,6,3,14,7,24,4,4,4,4,4,8,4,4,4)","(2,2,01060000000200000001030000000100000005000000000000000000000000000000000000000000000000000000000000000000244000000000000024400000000000002440000000000000244000000000000000000000000000000000000000000000000001030000000100000005000000000000000000284000000000000000000000000000002840000000000000F03F0000000000002A40000000000000F03F0000000000002A40000000000000000000000000000028400000000000000000,101,50.5,44,22,10001,99.019801980198,100,1,100,1,101,50.5,100,1)"}' passed
FROM (SELECT ST_AreaWeightedSummaryStats((geom, val)::geomval) as aws, id
      FROM (SELECT ST_GeomFromEWKT('POLYGON((0 0,0 10, 10 10, 10 0, 0 0))') as geom, 'a' as id, 100 as val
            UNION ALL
            SELECT ST_GeomFromEWKT('POLYGON((12 0,12 1, 13 1, 13 0, 12 0))') as geom, 'a' as id, 1 as val
            UNION ALL
            SELECT ST_GeomFromEWKT('POLYGON((10 0, 10 2, 12 2, 12 0, 10 0))') as geom, 'b' as id, 4 as val
            UNION ALL
            SELECT ST_GeomFromEWKT('POLYGON((10 2, 10 3, 12 3, 12 2, 10 2))') as geom, 'b' as id, 4 as val
            UNION ALL
            SELECT ST_GeomFromEWKT('GEOMETRYCOLLECTION EMPTY') as geom, 'b' as id, 2 as val
            UNION ALL
            SELECT null as geom, 'b' as id, 2 as val
           ) foo1
      GROUP BY id
     ) foo2
     
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
     
---------------------------------------------------------
-- Test 8 - ST_ExtractToRaster
---------------------------------------------------------
UNION ALL
SELECT '8.1'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'Test for null raster'::text description,
       ST_ExtractToRaster(null, 
                          'public', 
                          'test_extracttoraster', 
                          'geom', 
                          'val') IS NULL passed
---------------------------------------------------------
UNION ALL
SELECT '8.2'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'Test for empty raster'::text description,
       ST_IsEmpty(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(0, 0, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                          'public', 
                          'test_extracttoraster', 
                          'geom', 
                          'val')) passed
---------------------------------------------------------
UNION ALL
SELECT '8.3'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'Test for no band raster'::text description,
       ST_HasNoBand(ST_ExtractToRaster(ST_MakeEmptyRaster(10, 10, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), 
                          'public', 
                          'test_extracttoraster', 
                          'geom', 
                          'val')) passed
---------------------------------------------------------
UNION ALL
SELECT '8.4'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'Test COUNT_OF_VALUES_AT_PIXEL_CENTROID'::text description,
       (ST_DumpValues(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                                         'public', 
                                         'test_extracttoraster', 
                                         'geom', 
                                         'val', 
                                         'COUNT_OF_VALUES_AT_PIXEL_CENTROID'))
       ).valarray = '{{2,3},{3,2}}' passed
---------------------------------------------------------
UNION ALL
SELECT '8.5'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'Test MEAN_OF_VALUES_AT_PIXEL_CENTROID'::text description,
       (ST_DumpValues(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                                         'public', 
                                         'test_extracttoraster', 
                                         'geom', 
                                         'val', 
                                         'MEAN_OF_VALUES_AT_PIXEL_CENTROID'))
       ).valarray = '{{2,4},{3,3.5}}' passed
---------------------------------------------------------
UNION ALL
SELECT '8.6'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'Test COUNT_OF_POLYGONS'::text description,
       (ST_DumpValues(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                                         'public', 
                                         'test_extracttoraster', 
                                         'geom', 
                                         'val', 
                                         'COUNT_OF_POLYGONS'))
       ).valarray = '{{3,3},{3,3}}' passed
---------------------------------------------------------
UNION ALL
SELECT '8.7'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'Test COUNT_OF_LINESTRINGS'::text description,
       (ST_DumpValues(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                                         'public', 
                                         'test_extracttoraster', 
                                         'geom', 
                                         'val', 
                                         'COUNT_OF_LINESTRINGS'))
       ).valarray = '{{0,2},{2,0}}' passed
---------------------------------------------------------
UNION ALL
SELECT '8.8'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'Test COUNT_OF_POINTS'::text description,
       (ST_DumpValues(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                                         'public', 
                                         'test_extracttoraster', 
                                         'geom', 
                                         'val', 
                                         'COUNT_OF_POINTS'))
       ).valarray = '{{1,0},{0,2}}' passed
---------------------------------------------------------
UNION ALL
SELECT '8.9'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'Test COUNT_OF_GEOMETRIES'::text description,
       (ST_DumpValues(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                                         'public', 
                                         'test_extracttoraster', 
                                         'geom', 
                                         'val', 
                                         'COUNT_OF_GEOMETRIES'))
       ).valarray = '{{6,5},{5,7}}' passed
---------------------------------------------------------
UNION ALL
SELECT '8.10'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'Test VALUE_OF_BIGGEST'::text description,
       (ST_DumpValues(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                                         'public', 
                                         'test_extracttoraster', 
                                         'geom', 
                                         'val', 
                                         'VALUE_OF_BIGGEST'))
       ).valarray = '{{3,1},{3,1}}' passed
---------------------------------------------------------
UNION ALL
SELECT '8.11'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'Test VALUE_OF_MERGED_BIGGEST'::text description,
       (ST_DumpValues(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                                         'public', 
                                         'test_extracttoraster', 
                                         'geom', 
                                         'val', 
                                         'VALUE_OF_MERGED_BIGGEST'))
       ).valarray = '{{1,1},{1,1}}' passed
---------------------------------------------------------
UNION ALL
SELECT '8.12'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'Test MIN_AREA'::text description,
       (ST_DumpValues(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                                         'public', 
                                         'test_extracttoraster', 
                                         'geom', 
                                         'val', 
                                         'MIN_AREA'))
       ).valarray = '{{1.25,1},{1.25,1}}' passed
---------------------------------------------------------
UNION ALL
SELECT '8.13'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'Test VALUE_OF_MERGED_SMALLEST'::text description,
       (ST_DumpValues(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                                         'public', 
                                         'test_extracttoraster', 
                                         'geom', 
                                         'val', 
                                         'VALUE_OF_MERGED_SMALLEST'))
       ).valarray = '{{3,6},{3,6}}' passed
---------------------------------------------------------
UNION ALL
SELECT '8.14'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'Test SUM_OF_AREAS'::text description,
       (ST_DumpValues(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                                         'public', 
                                         'test_extracttoraster', 
                                         'geom', 
                                         'val', 
                                         'SUM_OF_AREAS'))
       ).valarray = '{{8,6},{8,6}}' passed
---------------------------------------------------------
UNION ALL
SELECT '8.15'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'Test PROPORTION_OF_COVERED_AREA'::text description,
       ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                          'public', 
                          'test_extracttoraster', 
                          'geom', 
                          'val', 
                          'PROPORTION_OF_COVERED_AREA') =                          '01000001000000000000001440000000000000F0BF000000000000000000000000000000400000000000000000000000000000000000000000020002004AFFFF7FFF6666663FCDCC4C3F6666663FCDCC4C3F'::raster passed
---------------------------------------------------------
UNION ALL
SELECT '8.16'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'Test AREA_WEIGHTED_MEAN_OF_VALUES'::text description,
       (ST_DumpValues(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                          'public', 
                          'test_extracttoraster', 
                          'geom', 
                          'val', 
                          'AREA_WEIGHTED_MEAN_OF_VALUES'))
       ).valarray = '{{1.9375,2.25},{1.9375,2.25}}' passed
---------------------------------------------------------
-- Test 9 - ST_GlobalRasterUnion
---------------------------------------------------------
UNION ALL
SELECT '9.1'::text number,
       'ST_GlobalRasterUnion'::text function_tested,
       'Test COUNT_OF_RASTER_VALUES_AT_PIXEL_CENTROID'::text description,
       (ST_DumpValues(ST_GlobalRasterUnion('public', 
                                           'test_globalrasterunion', 
                                           'rast',
                                           'COUNT_OF_RASTER_VALUES_AT_PIXEL_CENTROID'))
       ).valarray = '{{1,1,1,1,1,1,0,0,0},
                      {1,1,1,1,1,1,0,0,0},
                      {1,1,1,1,1,1,0,0,0},
                      {1,1,1,2,2,2,1,1,1},
                      {1,1,1,2,2,2,1,1,1},
                      {1,1,1,2,2,2,1,1,1},
                      {0,0,0,1,1,1,1,1,1},
                      {0,0,0,1,1,1,1,1,1},
                      {0,0,0,0,0,0,0,0,0}}' passed
---------------------------------------------------------
UNION ALL
SELECT '9.2'::text number,
       'ST_GlobalRasterUnion'::text function_tested,
       'Test defaulting to FIRST_RASTER_VALUE_AT_PIXEL_CENTROID'::text description,
       (ST_DumpValues(ST_GlobalRasterUnion('public', 'test_globalrasterunion', 'rast'))
       ).valarray = '{{0,5,10,10,15,20,NULL,NULL,NULL},
                      {1,6,11,11,16,21,NULL,NULL,NULL}, 
                      {2,7,12,12,17,22,NULL,NULL,NULL}, 
                      {2,7,12,12,17,22,15,20,25}, 
                      {3,8,13,13,18,23,16,21,26}, 
                      {4,9,14,14,19,24,17,22,27}, 
                      {NULL,NULL,NULL,3,8,13,18,23,28}, 
                      {NULL,NULL,NULL,4,9,14,19,24,29}, 
                      {NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL}}' passed
---------------------------------------------------------
UNION ALL
SELECT '9.3'::text number,
       'ST_GlobalRasterUnion'::text function_tested,
       'Test MIN_OF_RASTER_VALUES_AT_PIXEL_CENTROID'::text description,
       (ST_DumpValues(ST_GlobalRasterUnion('public', 
                                           'test_globalrasterunion', 
                                           'rast',
                                           'MIN_OF_RASTER_VALUES_AT_PIXEL_CENTROID'))
       ).valarray = '{{0,5,10,10,15,20,NULL,NULL,NULL},
                      {1,6,11,11,16,21,NULL,NULL,NULL},
                      {2,7,12,12,17,22,NULL,NULL,NULL},
                      {2,7,12,0,5,10,15,20,25},
                      {3,8,13,1,6,11,16,21,26},
                      {4,9,14,2,7,12,17,22,27},
                      {NULL,NULL,NULL,3,8,13,18,23,28},
                      {NULL,NULL,NULL,4,9,14,19,24,29},
                      {NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL}}' passed
---------------------------------------------------------
UNION ALL
SELECT '9.4'::text number,
       'ST_GlobalRasterUnion'::text function_tested,
       'Test MAX_OF_RASTER_VALUES_AT_PIXEL_CENTROID'::text description,
       (ST_DumpValues(ST_GlobalRasterUnion('public', 
                                           'test_globalrasterunion', 
                                           'rast',
                                           'MAX_OF_RASTER_VALUES_AT_PIXEL_CENTROID'))
       ).valarray = '{{0,5,10,10,15,20,NULL,NULL,NULL},
                      {1,6,11,11,16,21,NULL,NULL,NULL},
                      {2,7,12,12,17,22,NULL,NULL,NULL},
                      {2,7,12,12,17,22,15,20,25},
                      {3,8,13,13,18,23,16,21,26},
                      {4,9,14,14,19,24,17,22,27},
                      {NULL,NULL,NULL,3,8,13,18,23,28},
                      {NULL,NULL,NULL,4,9,14,19,24,29},
                      {NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL}}' passed
---------------------------------------------------------
UNION ALL
SELECT '9.5'::text number,
       'ST_GlobalRasterUnion'::text function_tested,
       'Test SUM_OF_RASTER_VALUES_AT_PIXEL_CENTROID'::text description,
       (ST_DumpValues(ST_GlobalRasterUnion('public', 
                                           'test_globalrasterunion', 
                                           'rast',
                                           'SUM_OF_RASTER_VALUES_AT_PIXEL_CENTROID'))
       ).valarray = '{{0,5,10,10,15,20,NULL,NULL,NULL},
                      {1,6,11,11,16,21,NULL,NULL,NULL},
                      {2,7,12,12,17,22,NULL,NULL,NULL},
                      {2,7,12,12,22,32,15,20,25},
                      {3,8,13,14,24,34,16,21,26},
                      {4,9,14,16,26,36,17,22,27},
                      {NULL,NULL,NULL,3,8,13,18,23,28},
                      {NULL,NULL,NULL,4,9,14,19,24,29},
                      {NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL}}' passed
---------------------------------------------------------
UNION ALL
SELECT '9.6'::text number,
       'ST_GlobalRasterUnion'::text function_tested,
       'Test MEAN_OF_RASTER_VALUES_AT_PIXEL_CENTROID'::text description,
       (ST_DumpValues(ST_GlobalRasterUnion('public', 
                                           'test_globalrasterunion', 
                                           'rast', 
                                           'MEAN_OF_RASTER_VALUES_AT_PIXEL_CENTROID'))
       ).valarray = '{{0,5,10,10,15,20,NULL,NULL,NULL},
                      {1,6,11,11,16,21,NULL,NULL,NULL},
                      {2,7,12,12,17,22,NULL,NULL,NULL},
                      {2,7,12,6,11,16,15,20,25},
                      {3,8,13,7,12,17,16,21,26},
                      {4,9,14,8,13,18,17,22,27},
                      {NULL,NULL,NULL,3,8,13,18,23,28},
                      {NULL,NULL,NULL,4,9,14,19,24,29},
                      {NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL}}' passed
---------------------------------------------------------
UNION ALL
SELECT '9.7'::text number,
       'ST_GlobalRasterUnion'::text function_tested,
       'Test STDDEVP_OF_RASTER_VALUES_AT_PIXEL_CENTROID'::text description,
       (ST_DumpValues(ST_GlobalRasterUnion('public', 
                                           'test_globalrasterunion', 
                                           'rast', 
                                           'STDDEVP_OF_RASTER_VALUES_AT_PIXEL_CENTROID'))
       ).valarray = '{{0,0,0,0,0,0,NULL,NULL,NULL},
                      {0,0,0,0,0,0,NULL,NULL,NULL},
                      {0,0,0,0,0,0,NULL,NULL,NULL},
                      {0,0,0,6,6,6,0,0,0},
                      {0,0,0,6,6,6,0,0,0},
                      {0,0,0,6,6,6,0,0,0},
                      {NULL,NULL,NULL,0,0,0,0,0,0},
                      {NULL,NULL,NULL,0,0,0,0,0,0},
                      {NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL}}' passed
---------------------------------------------------------
UNION ALL
SELECT '9.8'::text number,
       'ST_GlobalRasterUnion'::text function_tested,
       'Test RANGE_OF_RASTER_VALUES_AT_PIXEL_CENTROID'::text description,
       (ST_DumpValues(ST_GlobalRasterUnion('public', 
                                           'test_globalrasterunion', 
                                           'rast', 
                                           'RANGE_OF_RASTER_VALUES_AT_PIXEL_CENTROID'))
       ).valarray = '{{0,0,0,0,0,0,NULL,NULL,NULL},
                      {0,0,0,0,0,0,NULL,NULL,NULL},
                      {0,0,0,0,0,0,NULL,NULL,NULL},
                      {0,0,0,12,12,12,0,0,0},
                      {0,0,0,12,12,12,0,0,0},
                      {0,0,0,12,12,12,0,0,0},
                      {NULL,NULL,NULL,0,0,0,0,0,0},
                      {NULL,NULL,NULL,0,0,0,0,0,0},
                      {NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL}}' passed
---------------------------------------------------------
UNION ALL
SELECT '9.9'::text number,
       'ST_GlobalRasterUnion'::text function_tested,
       'Test AREA_WEIGHTED_MEAN_OF_RASTER_VALUES'::text description,
       (ST_DumpValues(ST_GlobalRasterUnion('public', 
                                           'test_globalrasterunion', 
                                           'rast', 
                                           'AREA_WEIGHTED_MEAN_OF_RASTER_VALUES'))
       ).valarray = '{{0,4,8,12,16,17,NULL,NULL,NULL},
                       {0,4,9,13,17,18,NULL,NULL,NULL},
                       {1,5,9,14,18,19,NULL,NULL,NULL},
                       {2,6,10,9,12,16,9,13,16},
                       {3,7,11,9,12,15,14,19,24},
                       {3,7,10,9,12,16,15,20,25},
                       {NULL,NULL,NULL,1,6,11,16,21,26},
                       {NULL,NULL,NULL,2,7,12,17,22,27},
                       {NULL,NULL,NULL,0,2,3,5,6,8}}' passed
---------------------------------------------------------

---------------------------------------------------------
-- This last line has to be commented out, with the line at the beginning,
-- to display only failing tests...
--) foo WHERE NOT passed;