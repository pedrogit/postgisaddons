-------------------------------------------------------------------------------
-- PostGIS PL/pgSQL Add-ons - Test file
-- Version 1.35 for PostGIS 2.1.x and PostgreSQL 9.x
-- http://github.com/pedrogit/postgisaddons
--
-- This is free software; you can redistribute and/or modify it under
-- the terms of the GNU General Public Licence. See the COPYING file.
--
-- Copyright (C) 2013-2017 Pierre Racine <pierre.racine@sbf.ulaval.ca>.
--
-- This test file return a table of four columns: 
--
-- - the 1st column (number) is the number of the test (e.g. 2.3) 
-- - the 2nd column (function_tested) is the name of the function being tested
-- - the 3rd column (description) is the description of the test
-- - the 4th column (passed) is the result of the test: 
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
SELECT 'e'::text, 5, ST_GeomFromText('LINESTRING(1 1.5, 9 1.5)')
UNION ALL
SELECT 'f'::text, 6, ST_GeomFromText('LINESTRING(4 0.5, 6 0.5)')
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
-- Table necessary to test ST_GeoTableSummary
DROP TABLE IF EXISTS test_geotablesummary;
CREATE TABLE test_geotablesummary AS
SELECT 1 id1, 1 id2, ST_MakePoint(0,0) geom -- point
UNION ALL
SELECT 2 id1, 2 id1, ST_MakePoint(0,0) geom -- duplicate point
UNION ALL
SELECT 3 id1, 3 id2, ST_MakePoint(0,0) geom -- duplicate point
UNION ALL
SELECT 4 id1, 4 id2, ST_MakePoint(0,1) geom -- other point
UNION ALL
SELECT 5 id1, 5 id2, ST_Difference(ST_Buffer(ST_MakePoint(0,0), 1), ST_Buffer(ST_MakePoint(0,-0.5), 0.1)) geom -- first polygon
UNION ALL
SELECT 6 id1, 6 id2, ST_Buffer(ST_MakePoint(0,1), 1) geom -- second polygon
UNION ALL
SELECT 7 id1, 7 id2, ST_MakeLine(ST_MakePoint(0,0), ST_MakePoint(0,1)) geom -- line
UNION ALL
SELECT 8 id1, 8 id2, ST_GeomFromText('GEOMETRYCOLLECTION EMPTY') geom -- empty geometry
UNION ALL
SELECT 9 id1, 9 id2, ST_GeomFromText('POINT EMPTY') geom -- empty point
UNION ALL
SELECT 10 id1, 10 id2, ST_GeomFromText('POLYGON EMPTY') geom -- empty polygon
UNION ALL
SELECT 11 id1, 11 id2, NULL::geometry geom -- null geometry
UNION ALL
SELECT 11 id1, 12 id2, ST_GeomFromText('POLYGON((0 0, 1 1, 1 2, 1 1, 0 0))'); -- invalid polygon

-----------------------------------------------------------
-- Table necessary to test ST_Histogram
DROP TABLE IF EXISTS test_histogram;
CREATE TABLE test_histogram AS
SELECT id, CASE WHEN id < 4 THEN NULL ELSE id END id2, r r1, r/10000000 r2
FROM (SELECT generate_series(1, 100) id, random() r FROM (SELECT setseed(0)) foo) foo2;

-----------------------------------------------------------
-- Comment out the following line and the last one of the file to display 
-- only failing tests
--SELECT * FROM (
-----------------------------------------------------------
-- The first table in the next WITH statement list all the function tested
-- with the number of test for each. It must be adjusted for every new test.
-- It is required to list tests which would not appear because they failed
-- by returning nothing.
WITH test_nb AS (
SELECT 'ST_DeleteBand'::text function_tested, 1 maj_num,  9 nb_test UNION ALL
SELECT 'ST_CreateIndexRaster'::text,          2,         15         UNION ALL
SELECT 'ST_RandomPoints'::text,               3,          3         UNION ALL
SELECT 'ST_ColumnExists'::text,               4,          4         UNION ALL
SELECT 'ST_AddUniqueID'::text,                5,          4         UNION ALL
SELECT 'ST_AreaWeightedSummaryStats'::text,   6,          2         UNION ALL
SELECT 'ST_ExtractToRaster'::text,            8,         17         UNION ALL
SELECT 'ST_GlobalRasterUnion'::text,          9,         12         UNION ALL
SELECT 'ST_BufferedUnion'::text,             10,          3         UNION ALL
SELECT 'ST_NBiggestExteriorRings'::text,     11,          2         UNION ALL
SELECT 'ST_BufferedSmooth'::text,            12,          1         UNION ALL
SELECT 'ST_DifferenceAgg'::text,             13,          3         UNION ALL
SELECT 'ST_TrimMulti'::text,                 14,          4         UNION ALL
SELECT 'ST_SplitAgg'::text,                  15,          5         UNION ALL
SELECT 'ST_HasBasicIndex'::text,             16,          4         UNION ALL
SELECT 'ST_GeoTableSummary'::text,           17,         17         UNION ALL
SELECT 'ST_SplitByGrid'::text,               18,          1         UNION ALL
SELECT 'ST_Histogram'::text,                 19,          9
),
test_series AS (
-- Build a table of function names with a sequence of number for each function to be tested
SELECT function_tested, maj_num, generate_series(1, nb_test)::text min_num 
FROM test_nb
)
SELECT coalesce(maj_num || '.' || min_num, b.number) number,
       coalesce(a.function_tested, 'ERROR: Insufficient number of test for ' || 
                b.function_tested || ' in the initial table...') function_tested,
       description, 
       NOT passed IS NULL AND (regexp_split_to_array(number, '\.'))[2] = min_num AND passed passed
FROM test_series a FULL OUTER JOIN (

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
       'Deletion of the only existing band'::text description,
        ST_NumBands(ST_DeleteBand(ST_AddBand(ST_MakeEmptyRaster(10, 10, 0, 0, 1),
                                             ARRAY[ROW(NULL, '8BUI', 255, 0)]::addbandarg[]), 1)) = 0 passed
---------------------------------------------------------
UNION ALL
SELECT '1.3'::text number,
       'ST_DeleteBand'::text function_tested,
       'Index too high (3)'::text description,
        ST_NumBands(ST_DeleteBand(rast, 3)) = 2 passed
FROM (SELECT ST_AddBand(ST_MakeEmptyRaster(10, 10, 0, 0, 1),
                        ARRAY[ROW(NULL, '8BUI', 255, 0), 
                              ROW(NULL, '16BUI', 1, 2)]::addbandarg[]) rast
     ) foo
---------------------------------------------------------
UNION ALL
SELECT '1.4'::text number,
       'ST_DeleteBand'::text function_tested,
       'Index zero'::text description,
        ST_NumBands(ST_DeleteBand(rast, 0)) = 2 passed
FROM (SELECT ST_AddBand(ST_MakeEmptyRaster(10, 10, 0, 0, 1),
                        ARRAY[ROW(NULL, '8BUI', 255, 0), 
                              ROW(NULL, '16BUI', 1, 2)]::addbandarg[]) rast
     ) foo
---------------------------------------------------------
UNION ALL
SELECT '1.5'::text number,
       'ST_DeleteBand'::text function_tested,
       'Index minus one'::text description,
        ST_NumBands(ST_DeleteBand(rast, -1)) = 2 passed
FROM (SELECT ST_AddBand(ST_MakeEmptyRaster(10, 10, 0, 0, 1),
                        ARRAY[ROW(NULL, '8BUI', 255, 0), 
                              ROW(NULL, '16BUI', 1, 2)]::addbandarg[]) rast
     ) foo
---------------------------------------------------------
UNION ALL
SELECT '1.6'::text number,
       'ST_DeleteBand'::text function_tested,
       'Null raster'::text description,
        ST_DeleteBand(null, 2) IS NULL passed
---------------------------------------------------------
UNION ALL
SELECT '1.7'::text number,
       'ST_DeleteBand'::text function_tested,
       'No band raster'::text description,
        ST_HasNoBand(ST_DeleteBand(ST_MakeEmptyRaster(10, 10, 0, 0, 1), 1)) passed
---------------------------------------------------------
UNION ALL
SELECT '1.8'::text number,
       'ST_DeleteBand'::text function_tested,
       'Empty raster'::text description,
        ST_IsEmpty(ST_DeleteBand(ST_MakeEmptyRaster(0, 0, 0, 0, 1), 1)) passed
---------------------------------------------------------
UNION ALL
SELECT '1.9'::text number,
       'ST_DeleteBand'::text function_tested,
       'Null band parameter'::text description,
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
UNION ALL
SELECT '4.4'::text number,
       'ST_ColumnExists'::text function_tested,
       'Mixed cases'::text description,
       ST_ColumnExists('TesT_AddUniqueID', 'ColuMn1') passed
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
       'Replacement of existing column2'::text description,
       ST_AddUniqueID('public', 'test_adduniqueid', 'column2', true) passed
---------------------------------------------------------
UNION ALL
SELECT '5.3'::text number,
       'ST_AddUniqueID'::text function_tested,
       'Default to public schema'::text description,
       ST_AddUniqueID('public', 'test_adduniqueid', 'column2', true) passed
---------------------------------------------------------
UNION ALL
SELECT '5.4'::text number,
       'ST_AddUniqueID'::text function_tested,
       'If index was created'::text description,
       ST_HasBasicIndex('public', 'test_adduniqueid', 'column2') passed

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
       'Null and empty geometry'::text description,
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
-- Test 8 - ST_ExtractToRaster
---------------------------------------------------------

UNION ALL
SELECT '8.1'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'Null raster'::text description,
       ST_ExtractToRaster(null, 
                          'public', 
                          'test_extracttoraster', 
                          'geom', 
                          'val') IS NULL passed
---------------------------------------------------------
UNION ALL
SELECT '8.2'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'Empty raster'::text description,
       ST_IsEmpty(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(0, 0, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                          'public', 
                          'test_extracttoraster', 
                          'geom', 
                          'val')) passed
---------------------------------------------------------
UNION ALL
SELECT '8.3'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'No band raster'::text description,
       ST_HasNoBand(ST_ExtractToRaster(ST_MakeEmptyRaster(10, 10, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), 
                          'public', 
                          'test_extracttoraster', 
                          'geom', 
                          'val')) passed
---------------------------------------------------------
UNION ALL
SELECT '8.4'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'COUNT_OF_VALUES_AT_PIXEL_CENTROID'::text description,
       (ST_DumpValues(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                                         'public', 
                                         'test_extracttoraster', 
                                         'geom', 
                                         'val', 
                                         'COUNT_OF_VALUES_AT_PIXEL_CENTROID'))
       ).valarray = '{{3,3},{2,2}}' passed
---------------------------------------------------------
UNION ALL
SELECT '8.5'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'MEAN_OF_VALUES_AT_PIXEL_CENTROID'::text description,
       (ST_DumpValues(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                                         'public', 
                                         'test_extracttoraster', 
                                         'geom', 
                                         'val', 
                                         'MEAN_OF_VALUES_AT_PIXEL_CENTROID'))
       ).valarray = '{{3,4},{2,3.5}}' passed
---------------------------------------------------------
UNION ALL
SELECT '8.6'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'COUNT_OF_POLYGONS'::text description,
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
       'COUNT_OF_LINESTRINGS'::text description,
       (ST_DumpValues(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                                         'public', 
                                         'test_extracttoraster', 
                                         'geom', 
                                         'val', 
                                         'COUNT_OF_LINESTRINGS'))
       ).valarray = '{{1,1},{1,1}}' passed
---------------------------------------------------------
UNION ALL
SELECT '8.8'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'COUNT_OF_POINTS'::text description,
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
       'COUNT_OF_GEOMETRIES'::text description,
       (ST_DumpValues(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                                         'public', 
                                         'test_extracttoraster', 
                                         'geom', 
                                         'val', 
                                         'COUNT_OF_GEOMETRIES'))
       ).valarray = '{{5,4},{4,6}}' passed
---------------------------------------------------------
UNION ALL
SELECT '8.10'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'VALUE_OF_BIGGEST'::text description,
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
       'VALUE_OF_MERGED_BIGGEST'::text description,
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
       'MIN_AREA'::text description,
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
       'VALUE_OF_MERGED_SMALLEST'::text description,
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
       'SUM_OF_AREAS'::text description,
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
       'PROPORTION_OF_COVERED_AREA'::text description,
       ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                          'public', 
                          'test_extracttoraster', 
                          'geom', 
                          'val', 
                          'PROPORTION_OF_COVERED_AREA') = '01000001000000000000001440000000000000F0BF000000000000000000000000000000400000000000000000000000000000000000000000020002004AFFFF7FFF6666663FCDCC4C3F6666663FCDCC4C3F'::raster passed
---------------------------------------------------------
UNION ALL
SELECT '8.16'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'AREA_WEIGHTED_MEAN_OF_VALUES'::text description,
       (ST_DumpValues(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                          'public', 
                          'test_extracttoraster', 
                          'geom', 
                          'val', 
                          'AREA_WEIGHTED_MEAN_OF_VALUES'))
       ).valarray = '{{1.9375,2.25},{1.9375,2.25}}' passed
---------------------------------------------------------
UNION ALL
SELECT '8.17'::text number,
       'ST_ExtractToRaster'::text function_tested,
       'SUM_OF_LENGTHS'::text description,
       (ST_DumpValues(ST_ExtractToRaster(ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF'), 
                                         'public', 
                                         'test_extracttoraster', 
                                         'geom', 
                                         'val', 
                                         'SUM_OF_LENGTHS'))
       ).valarray = '{{4,4},{1,1}}' passed

---------------------------------------------------------
-- Test 9 - ST_GlobalRasterUnion
---------------------------------------------------------

UNION ALL
SELECT '9.1'::text number,
       'ST_GlobalRasterUnion'::text function_tested,
       'COUNT_OF_RASTER_VALUES_AT_PIXEL_CENTROID'::text description,
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
       'Default to FIRST_RASTER_VALUE_AT_PIXEL_CENTROID'::text description,
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
       'MIN_OF_RASTER_VALUES_AT_PIXEL_CENTROID'::text description,
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
       'MAX_OF_RASTER_VALUES_AT_PIXEL_CENTROID'::text description,
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
       'SUM_OF_RASTER_VALUES_AT_PIXEL_CENTROID'::text description,
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
       'MEAN_OF_RASTER_VALUES_AT_PIXEL_CENTROID'::text description,
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
       'STDDEVP_OF_RASTER_VALUES_AT_PIXEL_CENTROID'::text description,
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
       'RANGE_OF_RASTER_VALUES_AT_PIXEL_CENTROID'::text description,
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
       'AREA_WEIGHTED_SUM_OF_RASTER_VALUES'::text description,
       (ST_DumpValues(ST_GlobalRasterUnion('public', 
                                           'test_globalrasterunion', 
                                           'rast', 
                                           'AREA_WEIGHTED_SUM_OF_RASTER_VALUES'))
       ).valarray = '{{0,2,5,8,11,12,NULL,NULL,NULL},
                      {0,3,6,9,12,13,NULL,NULL,NULL},
                      {1,4,7,10,13,13,NULL,NULL,NULL},
                      {1,4,7,10,15,18,6,9,12},
                      {2,5,8,11,17,21,10,13,17},
                      {2,5,7,11,16,20,11,14,18},
                      {NULL,NULL,NULL,1,4,8,11,15,18},
                      {NULL,NULL,NULL,1,5,8,12,16,19},
                      {NULL,NULL,NULL,0,1,2,3,4,5}}' passed
---------------------------------------------------------
UNION ALL
SELECT '9.10'::text number,
       'ST_GlobalRasterUnion'::text function_tested,
       'SUM_OF_AREA_PROPORTIONAL_RASTER_VALUES'::text description,
       (ST_DumpValues(ST_GlobalRasterUnion('public', 
                                           'test_globalrasterunion', 
                                           'rast', 
                                           'SUM_OF_AREA_PROPORTIONAL_RASTER_VALUES'))
       ).valarray = '{{0,2,5,8,11,12,NULL,NULL,NULL},
                      {0,3,6,9,12,13,NULL,NULL,NULL},
                      {1,4,7,10,13,13,NULL,NULL,NULL},
                      {1,4,7,10,16,20,9,13,16},
                      {2,5,8,11,18,24,14,19,24},
                      {2,5,7,11,18,23,15,20,25},
                      {NULL,NULL,NULL,1,6,11,16,21,26},
                      {NULL,NULL,NULL,2,7,12,17,22,27},
                      {NULL,NULL,NULL,0,2,3,5,6,8}}' passed
---------------------------------------------------------
UNION ALL
SELECT '9.11'::text number,
       'ST_GlobalRasterUnion'::text function_tested,
       'AREA_WEIGHTED_MEAN_OF_RASTER_VALUES'::text description,
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
UNION ALL
SELECT '9.12'::text number,
       'ST_GlobalRasterUnion'::text function_tested,
       'AREA_WEIGHTED_MEAN_OF_RASTER_VALUES_2'::text description,
       (ST_DumpValues(ST_GlobalRasterUnion('public', 
                                           'test_globalrasterunion', 
                                           'rast', 
                                           'AREA_WEIGHTED_MEAN_OF_RASTER_VALUES_2'))
       ).valarray = '{{0,4,8,12,16,20,NULL,NULL,NULL},
                      {0,4,9,13,17,20,NULL,NULL,NULL},
                      {1,5,9,14,18,21,NULL,NULL,NULL},
                      {2,6,10,9,12,16,13,18,23},
                      {3,7,11,9,12,15,14,19,24},
                      {4,8,12,9,12,16,15,20,25},
                      {NULL,NULL,NULL,2,6,11,16,21,26},
                      {NULL,NULL,NULL,3,7,12,17,22,27},
                      {NULL,NULL,NULL,4,7,12,17,22,27}}' passed

---------------------------------------------------------
-- Test 10 - ST_BufferedUnion
---------------------------------------------------------

UNION ALL
SELECT '10.1'::text number,
       'ST_BufferedUnion'::text function_tested,
       'Basic test'::text description,
       ST_AsText(ST_BufferedUnion(geom, 0.05)) = 'POLYGON((0 0,20 0,20 -20,0 -20,0 0))' passed
FROM (SELECT 1 id, 'POLYGON((0 0,10 0,10 -9.9999,0 -10,0 0))'::geometry geom
      UNION ALL
      SELECT 2 id, 'POLYGON((10 0,20 0,20 -9.9999,10 -10,10 0))'::geometry
      UNION ALL
      SELECT 3 id, 'POLYGON((0 -10,10 -10.0001,10 -20,0 -20,0 -10))'::geometry
      UNION ALL
      SELECT 4 id, 'POLYGON((10 -10,20 -10,20 -20,10 -20,10 -10))'::geometry
     ) foo
---------------------------------------------------------
UNION ALL
SELECT '10.2'::text number,
       'ST_BufferedUnion'::text function_tested,
       'Null geometry'::text description,
       ST_AsText(ST_BufferedUnion(geom, 0.05)) = 'POLYGON((10 0,20 0,20 -20,0 -20,0 -10,10 -10.0001,10 0))' passed
FROM (SELECT 1 id, null geom
      UNION ALL
      SELECT 2 id, 'POLYGON((10 0,20 0,20 -9.9999,10 -10,10 0))'::geometry
      UNION ALL
      SELECT 3 id, 'POLYGON((0 -10,10 -10.0001,10 -20,0 -20,0 -10))'::geometry
      UNION ALL
      SELECT 4 id, 'POLYGON((10 -10,20 -10,20 -20,10 -20,10 -10))'::geometry
     ) foo
---------------------------------------------------------
UNION ALL
SELECT '10.3'::text number,
       'ST_BufferedUnion'::text function_tested,
       'Null buffer size'::text description,
       ST_AsText(ST_BufferedUnion(geom, null)) = 'POLYGON((0 0,10 0,20 0,20 -9.9999,10 -10,10 -9.9999,0 -10,0 0))' passed
FROM (SELECT 1 id, 'POLYGON((0 0,10 0,10 -9.9999,0 -10,0 0))'::geometry geom
      UNION ALL
      SELECT 2 id, 'POLYGON((10 0,20 0,20 -9.9999,10 -10,10 0))'::geometry
     ) foo

---------------------------------------------------------
-- Test 11 - ST_NBiggestExteriorRings
---------------------------------------------------------

UNION ALL
SELECT '11.1'::text number,
       'ST_NBiggestExteriorRings'::text function_tested,
       'Basic test defaulting to AREA'::text description,
       array_agg(geom) = '{"POLYGON((40 0,40 10,52 10,52 0,40 0))",
                           "POLYGON((20 0,20 5,20 10,30 10,30 0,20 0))"}' passed
FROM (SELECT ST_AsText(
               ST_NBiggestExteriorRings(
                 ST_GeomFromText('MULTIPOLYGON( ((0 0, 0 5, 0 10, 8 10, 8 0, 0 0)), 
                                                ((20 0, 20 5, 20 10, 30 10, 30 0, 20 0)), 
                                                ((40 0, 40 10, 52 10, 52 0, 40 0)) )'), 
                 2)) geom) foo
---------------------------------------------------------
UNION ALL
SELECT '11.2'::text number,
       'ST_NBiggestExteriorRings'::text function_tested,
       'Basic test with NBPOINTS'::text description,
       array_agg(geom) = '{"POLYGON((0 0,0 5,0 10,8 10,8 0,0 0))",
                           "POLYGON((20 0,20 5,20 10,30 10,30 0,20 0))"}' passed
FROM (SELECT ST_AsText(
               ST_NBiggestExteriorRings(
                 ST_GeomFromText('MULTIPOLYGON( ((0 0, 0 5, 0 10, 8 10, 8 0, 0 0)), 
                                                ((20 0, 20 5, 20 10, 30 10, 30 0, 20 0)), 
                                                ((40 0, 40 10, 52 10, 52 0, 40 0)) )'), 
                 2, 'NBPOINTS')) geom) foo

---------------------------------------------------------
-- Test 12 - ST_BufferedSmooth
---------------------------------------------------------

UNION ALL
SELECT '12.1'::text number,
       'ST_BufferedSmooth'::text function_tested,
       'Basic test'::text description,
       ST_NPoints(ST_BufferedSmooth(
          ST_GeomFromText('POLYGON((-2  1, -5  5, -1  2, 0  5, 1  2,  5  5,  2  1, 
                                     5  0,  2 -1,  5 -5, 1 -2, 0 -5, -1 -2, -5 -5, 
                                    -2 -1, -5  0, -2  1))'), 
          1)) = 113

---------------------------------------------------------
-- Test 13 - ST_DifferenceAgg
---------------------------------------------------------

UNION ALL
(WITH overlappingtable AS (
  SELECT 1 id, ST_GeomFromText('POLYGON((0 1, 3 2, 3 0, 0 1))') geom
  UNION ALL
  SELECT 2 id, ST_GeomFromText('POLYGON((1 1, 4 2, 4 0, 1 1))')
  UNION ALL
  SELECT 3 id, ST_GeomFromText('POLYGON((2 1, 5 2, 5 0, 2 1))')
  UNION ALL
  SELECT 4 id, ST_GeomFromText('POLYGON((3 1, 6 2, 6 0, 3 1))')
)
SELECT '13.1'::text number,
       'ST_DifferenceAgg'::text function_tested,
       'Basic test'::text description,
       ST_Union(geom)::text = '010300000001000000130000000000000000000000000000000000F03F000000000000084000000000000000400000000000000840ABAAAAAAAAAAFA3F000000000000F03F000000000000F03F000000000000104000000000000000400000000000001040ABAAAAAAAAAAFA3F0000000000000040000000000000F03F000000000000144000000000000000400000000000001440ABAAAAAAAAAAFA3F0000000000000840000000000000F03F00000000000018400000000000000040000000000000184000000000000000000000000000001440565555555555D53F000000000000144000000000000000000000000000001040565555555555D53F000000000000104000000000000000000000000000000840565555555555D53F000000000000084000000000000000000000000000000000000000000000F03F' passed
FROM (SELECT ST_DifferenceAgg(a.geom, b.geom) geom
      FROM overlappingtable a, 
           overlappingtable b
      WHERE a.id = b.id OR 
            ((ST_Contains(a.geom, b.geom) OR ST_Contains(b.geom, a.geom) OR ST_Overlaps(a.geom, b.geom)) AND 
             (a.id < b.id))
      GROUP BY a.id
     ) foo
)
---------------------------------------------------------
UNION ALL
(WITH overlapping AS (
  SELECT 1 id, ST_GeomFromText('POLYGON((0 1, 3 2, 3 0, 0 1))') geom
  UNION ALL
  SELECT 2 id, null
  UNION ALL
  SELECT 3 id, ST_GeomFromText('POLYGON((2 1, 5 2, 5 0, 2 1))')
  UNION ALL
  SELECT 4 id, ST_GeomFromText('POLYGON((3 1, 6 2, 6 0, 3 1))')
)
SELECT '13.2'::text number,
       'ST_DifferenceAgg'::text function_tested,
       'Null geometry'::text description,
       ST_Union(geom)::text = '0103000000010000000D0000000000000000000000000000000000F03F000000000000084000000000000000400000000000000840555555555555F53F000000000000144000000000000000400000000000001440ABAAAAAAAAAAFA3F0000000000000840000000000000F03F00000000000018400000000000000040000000000000184000000000000000000000000000001440565555555555D53F000000000000144000000000000000000000000000000840555555555555E53F000000000000084000000000000000000000000000000000000000000000F03F' passed
FROM (SELECT ST_DifferenceAgg(a.geom, b.geom) geom
      FROM overlapping a, 
           overlapping b
      WHERE a.id = b.id OR 
            ((ST_Contains(a.geom, b.geom) OR ST_Contains(b.geom, a.geom) OR ST_Overlaps(a.geom, b.geom)) AND 
             (a.id < b.id))
      GROUP BY a.id
     ) foo
)
---------------------------------------------------------
UNION ALL
(WITH overlappingtable AS (
  SELECT 1 id, ST_GeomFromText('POLYGON((0 1, 3 2, 3 0, 0 1))') geom
  UNION ALL
  SELECT 2 id, ST_GeomFromText('POLYGON((0 1, 3 2, 3 0, 0 1))')
  UNION ALL
  SELECT 3 id, ST_GeomFromText('POLYGON((0 1, 3 2, 3 0, 0 1))')
)
SELECT '13.3'::text number,
       'ST_DifferenceAgg'::text function_tested,
       'Make sure that only the first equivalent geometry is not removed (all the others should be removed.)'::text description,
       geom::text = '010300000001000000040000000000000000000000000000000000F03F00000000000008400000000000000040000000000000084000000000000000000000000000000000000000000000F03F' passed
FROM (SELECT ST_DifferenceAgg(a.geom, b.geom) geom
      FROM overlappingtable a, 
           overlappingtable b
      WHERE a.id = b.id OR 
            ((ST_Contains(a.geom, b.geom) OR ST_Contains(b.geom, a.geom) OR ST_Overlaps(a.geom, b.geom)) AND 
             (a.id < b.id))
      GROUP BY a.id
      HAVING ST_Area(ST_DifferenceAgg(a.geom, b.geom)) > 0.00001 AND NOT ST_IsEmpty(ST_DifferenceAgg(a.geom, b.geom))
     ) foo
)

---------------------------------------------------------
-- Test 14 - ST_TrimMulti
---------------------------------------------------------

UNION ALL
SELECT '14.1'::text number,
       'ST_TrimMulti'::text function_tested,
       'Basic test defaulting to minarea = 0.0'::text description,
       ST_TrimMulti(
         ST_GeomFromText('MULTIPOLYGON(((2 2, 2 3, 2 4, 2 2)),
                                       ((0 0, 0 1, 1 1, 1 0, 0 0)))')) =
         'POLYGON((0 0,0 1,1 1,1 0,0 0))'::geometry passed
---------------------------------------------------------
UNION ALL
SELECT '14.2'::text number,
       'ST_TrimMulti'::text function_tested,
       'Null geometry'::text description,
       ST_TrimMulti(null, 0.00001) IS NULL passed
---------------------------------------------------------
UNION ALL
SELECT '14.3'::text number,
       'ST_TrimMulti'::text function_tested,
       'Empty geometry'::text description,
       ST_TrimMulti('GEOMETRYCOLLECTION EMPTY'::geometry, 0.00001) IS NULL passed
---------------------------------------------------------
UNION ALL
SELECT '14.4'::text number,
       'ST_TrimMulti'::text function_tested,
       'Geometry collection'::text description,
       ST_TrimMulti(
         ST_Collect(ARRAY['MULTIPOLYGON(((2 2, 2 3, 2 4, 2 2)),
                                        ((0 0, 0 1, 1 1, 1 0, 0 0)))'::geometry, 
                          'POINT(1 1)'::geometry, 
                          'LINESTRING(0 0, 1 1, 2 1)'::geometry])) = 
       'POLYGON((0 0,0 1,1 1,1 0,0 0))'::geometry passed

---------------------------------------------------------
-- Test 15 - ST_SplitAgg
---------------------------------------------------------

UNION ALL
(WITH geomtable AS (
SELECT 1 id, ST_GeomFromText('POLYGON((0 0, 0 2, 2 2, 2 0, 0 0), (0.2 0.5, 0.2 1.5, 0.8 1.5, 0.8 0.5, 0.2 0.5))') geom
UNION ALL
SELECT 2 id, ST_GeomFromText('POLYGON((1 0.2, 1 1, 3 1, 3 0.2, 1 0.2))') geom
UNION ALL
SELECT 3 id, ST_GeomFromText('POLYGON((1.5 0.8, 1.5 1.2, 2.5 1.2, 2.5 0.8, 1.5 0.8))') geom
UNION ALL
SELECT 4 id, ST_GeomFromText('MULTIPOLYGON(((3 0, 3 2, 5 2, 5 0, 3 0)), ((4 3, 4 4, 5 4, 5 3, 4 3)))') geom
)
SELECT '15.1'::text number,
       'ST_SplitAgg'::text function_tested,
       'Basic test'::text description,
       array_agg(geomtxt) = 
       '{"POLYGON((0 0,0 2,2 2,2 1.2,1.5 1.2,1.5 1,1 1,1 0.2,2 0.2,2 0,0 0),(0.2 1.5,0.2 0.5,0.8 0.5,0.8 1.5,0.2 1.5))",
         "POLYGON((2 0.8,2 0.2,1 0.2,1 1,1.5 1,1.5 0.8,2 0.8))",
         "POLYGON((2 1.2,2 1,1.5 1,1.5 1.2,2 1.2))",
         "POLYGON((2 1,2 0.8,1.5 0.8,1.5 1,2 1))"}' passed
FROM (SELECT ST_AsText(unnest(ST_SplitAgg(a.geom, b.geom, 0.00001))) geomtxt
      FROM geomtable a, geomtable b
      WHERE a.id = 1) foo)
---------------------------------------------------------
UNION ALL
(WITH geomtable AS (
SELECT 1 id, ST_GeomFromText('POLYGON((0 0, 0 2, 2 2, 2 0, 0 0), (0.2 0.5, 0.2 1.5, 0.8 1.5, 0.8 0.5, 0.2 0.5))') geom
UNION ALL
SELECT 2 id, ST_GeomFromText('POLYGON((1 0.2, 1 1, 3 1, 3 0.2, 1 0.2))') geom
UNION ALL
SELECT 3 id, null geom
UNION ALL
SELECT 4 id, ST_GeomFromText('MULTIPOLYGON(((3 0, 3 2, 5 2, 5 0, 3 0)), ((4 3, 4 4, 5 4, 5 3, 4 3)))') geom
)
SELECT '15.2'::text number,
       'ST_SplitAgg'::text function_tested,
       'Null geometry on the "splitting" side'::text description,
       array_agg(geomtxt) = 
       '{"POLYGON((0 0,0 2,2 2,2 1,1 1,1 0.2,2 0.2,2 0,0 0),(0.2 1.5,0.2 0.5,0.8 0.5,0.8 1.5,0.2 1.5))",
         "POLYGON((2 1,2 0.2,1 0.2,1 1,2 1))"}' passed
FROM (SELECT ST_AsText(unnest(ST_SplitAgg(a.geom, b.geom, 0.00001))) geomtxt
      FROM geomtable a, geomtable b
      WHERE a.id = 1) foo)
---------------------------------------------------------
UNION ALL
(WITH geomtable AS (
SELECT 3 id, ST_GeomFromText('POLYGON((0 0, 0 2, 2 2, 2 0, 0 0), (0.2 0.5, 0.2 1.5, 0.8 1.5, 0.8 0.5, 0.2 0.5))') geom
UNION ALL
SELECT 2 id, ST_GeomFromText('POLYGON((1 0.2, 1 1, 3 1, 3 0.2, 1 0.2))') geom
UNION ALL
SELECT 1 id, null geom
UNION ALL
SELECT 4 id, ST_GeomFromText('MULTIPOLYGON(((3 0, 3 2, 5 2, 5 0, 3 0)), ((4 3, 4 4, 5 4, 5 3, 4 3)))') geom
)
SELECT '15.3'::text number,
       'ST_SplitAgg'::text function_tested,
       'Null geometry on the "to split" side. Should be null.'::text description,
       array_agg(geomtxt) IS NULL passed
FROM (SELECT ST_AsText(unnest(ST_SplitAgg(a.geom, b.geom, 0.00001))) geomtxt
      FROM geomtable a, geomtable b
      WHERE a.id = 1) foo)
---------------------------------------------------------
UNION ALL
(WITH geomtable AS (
SELECT 3 id, ST_GeomFromText('POLYGON((0 0, 0 2, 2 2, 2 0, 0 0), (0.2 0.5, 0.2 1.5, 0.8 1.5, 0.8 0.5, 0.2 0.5))') geom
UNION ALL
SELECT 2 id, ST_GeomFromText('POLYGON((1 0.2, 1 1, 3 1, 3 0.2, 1 0.2))') geom
UNION ALL
SELECT 1 id, 'GEOMETRYCOLLECTION EMPTY'::geometry geom
UNION ALL
SELECT 4 id, ST_GeomFromText('MULTIPOLYGON(((3 0, 3 2, 5 2, 5 0, 3 0)), ((4 3, 4 4, 5 4, 5 3, 4 3)))') geom
)
SELECT '15.4'::text number,
       'ST_SplitAgg'::text function_tested,
       'Empty geometry on the "to split" side. Should be null.'::text description,
       array_agg(geomtxt) IS NULL passed
FROM (SELECT ST_AsText(unnest(ST_SplitAgg(a.geom, b.geom, 0.00001))) geomtxt
      FROM geomtable a, geomtable b
      WHERE a.id = 1) foo)
---------------------------------------------------------
UNION ALL
(WITH geomtable AS (
SELECT 1 id, ST_GeomFromText('POLYGON((0 0, 0 2, 2 2, 2 0, 0 0), (0.2 0.5, 0.2 1.5, 0.8 1.5, 0.8 0.5, 0.2 0.5))') geom
UNION ALL
SELECT 2 id, ST_GeomFromText('POLYGON((1 0.2, 1 1, 3 1, 3 0.2, 1 0.2))') geom
UNION ALL
SELECT 3 id, 'GEOMETRYCOLLECTION EMPTY'::geometry geom
UNION ALL
SELECT 4 id, ST_GeomFromText('MULTIPOLYGON(((3 0, 3 2, 5 2, 5 0, 3 0)), ((4 3, 4 4, 5 4, 5 3, 4 3)))') geom
)
SELECT '15.5'::text number,
       'ST_SplitAgg'::text function_tested,
       'Empty geometry on the "splitting" side'::text description,
       array_agg(geomtxt) = 
       '{"POLYGON((0 0,0 2,2 2,2 1,1 1,1 0.2,2 0.2,2 0,0 0),(0.2 1.5,0.2 0.5,0.8 0.5,0.8 1.5,0.2 1.5))",
         "POLYGON((2 1,2 0.2,1 0.2,1 1,2 1))"}' passed
FROM (SELECT ST_AsText(unnest(ST_SplitAgg(a.geom, b.geom, 0.00001))) geomtxt
      FROM geomtable a, geomtable b
      WHERE a.id = 1) foo)

---------------------------------------------------------
-- Test 16 - ST_HasBasicIndex
---------------------------------------------------------

UNION ALL
SELECT '16.1'::text number,
       'ST_HasBasicIndex'::text function_tested,
       'Existence of an index on the column1 column of public.test_adduniqueid'::text description,
       NOT ST_HasBasicIndex('public', 'test_adduniqueid', 'column1') passed
---------------------------------------------------------
UNION ALL
SELECT '16.2'::text number,
       'ST_HasBasicIndex'::text function_tested,
       'Existence of an index on the column2 column of public.test_adduniqueid'::text description,
       ST_HasBasicIndex('public', 'test_adduniqueid', 'column2') passed
---------------------------------------------------------
UNION ALL
SELECT '16.3'::text number,
       'ST_HasBasicIndex'::text function_tested,
       'Default to public schema'::text description,
       ST_HasBasicIndex('test_adduniqueid', 'column2') passed
---------------------------------------------------------
UNION ALL
SELECT '16.4'::text number,
       'ST_HasBasicIndex'::text function_tested,
       'Mixed cases'::text description,
       ST_HasBasicIndex('Test_AddUniqueID', 'Column2') passed
       
---------------------------------------------------------
-- Test 17 - ST_GeoTableSummary
---------------------------------------------------------

UNION ALL
SELECT '17.1'::text number,
       'ST_GeoTableSummary'::text function_tested,
       'Duplicates in column id1'::text description,
       idsandtypes = '11' AND countsandareas = 2 passed
FROM ST_GeoTableSummary('public', 'test_geotablesummary', 'geom', 'id1')
WHERE summary = '1'
---------------------------------------------------------
UNION ALL
SELECT '17.2'::text number,
       'ST_GeoTableSummary'::text function_tested,
       'Duplicates in column id2'::text description,
       'No duplicate IDs...' = idsandtypes AND countsandareas IS NULL passed
FROM ST_GeoTableSummary('public', 'test_geotablesummary', 'geom', 'id2')
WHERE summary = '1'
---------------------------------------------------------
UNION ALL
SELECT '17.3'::text number,
       'ST_GeoTableSummary'::text function_tested,
       'uidcolumn missing'::text description,
       (array_agg(idsandtypes))[1] = '''id'' does not exists... Skipping Summary 1' AND
       (array_agg(idsandtypes))[2] = 'DUPLICATE GEOMETRIES IDS (id2)' passed
FROM ST_GeoTableSummary('public', 'test_geotablesummary', 'geom')
WHERE summary = '1' OR left(summary, 9) = 'SUMMARY 2'
---------------------------------------------------------
UNION ALL
SELECT '17.4'::text number,
       'ST_GeoTableSummary'::text function_tested,
       'uidcolumn = ''id'''::text description,
       idsandtypes = 'DUPLICATE GEOMETRIES IDS (id)' passed
FROM ST_GeoTableSummary('public', 'test_geotablesummary', 'geom', 'id')
WHERE left(summary, 9) = 'SUMMARY 2'
---------------------------------------------------------
UNION ALL
SELECT '17.5'::text number,
       'ST_GeoTableSummary'::text function_tested,
       'uidcolumn not numeric or text'::text description,
       '''geom'' is not of type numeric or text... Skipping Summary 1' = idsandtypes AND countsandareas IS NULL passed
FROM ST_GeoTableSummary('public', 'test_geotablesummary', 'geom', 'geom')
WHERE summary = '1'
---------------------------------------------------------
UNION ALL
SELECT '17.6'::text number,
       'ST_GeoTableSummary'::text function_tested,
       'Duplicate geometries results'::text description,
       (array_agg(idsandtypes ORDER BY idsandtypes))[1] = '1, 2, 3' AND 
       (array_agg(idsandtypes ORDER BY idsandtypes))[2] = '8, 9, 10' AND
       (array_agg(countsandareas ORDER BY idsandtypes))[1] = 3 AND 
       (array_agg(countsandareas ORDER BY idsandtypes))[2] = 3 AND
       (array_agg(geom ORDER BY idsandtypes))[1]::text  = '010100000000000000000000000000000000000000' AND 
       ((array_agg(geom ORDER BY idsandtypes))[2]::text  = '0101000000000000000000F87F000000000000F87F' OR (array_agg(geom ORDER BY idsandtypes))[2]::text = '010300000000000000') AND
       (array_agg(query ORDER BY idsandtypes))[1]::text = 'SELECT * FROM public.test_geotablesummary WHERE id = ANY(ARRAY[1, 2, 3]);' AND 
       (array_agg(query ORDER BY idsandtypes))[2]::text = 'SELECT * FROM public.test_geotablesummary WHERE id = ANY(ARRAY[8, 9, 10]);' passed
FROM ST_GeoTableSummary('public', 'test_geotablesummary', 'geom', 'id')
WHERE summary = '2' 
---------------------------------------------------------
UNION ALL
SELECT '17.7'::text number,
       'ST_GeoTableSummary'::text function_tested,
       'Overlapping geometries results'::text description,
       idsandtypes = 'ERROR: Consider fixing invalid geometries and convert ST_GeometryCollection before testing for overlaps...' passed
FROM ST_GeoTableSummary('public', 'test_geotablesummary', 'geom', 'id', null, ARRAY['OVL'])
WHERE summary = '3'
---------------------------------------------------------
UNION ALL
SELECT '17.8'::text number,
       'ST_GeoTableSummary'::text function_tested,
       'Geometry types results'::text description,
       (array_agg(countsandareas))[1] = 1 AND 
       (array_agg(countsandareas))[2] = 2 AND 
       (array_agg(countsandareas))[3] = 1 AND 
       (array_agg(countsandareas))[4] = 1 AND 
       (array_agg(countsandareas))[5] = 4 AND 
       (array_agg(countsandareas))[6] = 1 AND 
       (array_agg(countsandareas))[7] = 1 AND 
       (array_agg(countsandareas))[8] = 1 AND 
       (array_agg(query))[1]::text = 'SELECT * FROM public.test_geotablesummary WHERE geom IS NULL;' AND 
       (array_agg(query))[2]::text = 'SELECT * FROM public.test_geotablesummary WHERE ST_IsValid(geom) AND NOT ST_IsEmpty(geom) AND ST_GeometryType(geom) = ''ST_Polygon'';' AND 
       (array_agg(query))[3]::text = 'SELECT * FROM public.test_geotablesummary WHERE ST_IsEmpty(geom) AND ST_GeometryType(geom) = ''ST_Polygon'';' AND 
       (array_agg(query))[4]::text = 'SELECT * FROM public.test_geotablesummary WHERE NOT ST_IsValid(geom) AND ST_GeometryType(geom) = ''ST_Polygon'';' AND 
       (array_agg(query))[5]::text = 'SELECT * FROM public.test_geotablesummary WHERE ST_IsValid(geom) AND NOT ST_IsEmpty(geom) AND ST_GeometryType(geom) = ''ST_Point'';' AND 
       (array_agg(query))[6]::text = 'SELECT * FROM public.test_geotablesummary WHERE ST_IsEmpty(geom) AND ST_GeometryType(geom) = ''ST_Point'';' AND 
       (array_agg(query))[7]::text = 'SELECT * FROM public.test_geotablesummary WHERE ST_IsValid(geom) AND NOT ST_IsEmpty(geom) AND ST_GeometryType(geom) = ''ST_LineString'';' AND 
       (array_agg(query))[8]::text = 'SELECT * FROM public.test_geotablesummary WHERE ST_IsEmpty(geom) AND ST_GeometryType(geom) = ''ST_GeometryCollection'';' passed
FROM ST_GeoTableSummary('public', 'test_geotablesummary', 'geom', 'id')
WHERE summary = '5'
---------------------------------------------------------
UNION ALL
SELECT '17.9'::text number,
       'ST_GeoTableSummary'::text function_tested,
       'Vertex statistics results'::text description,
       (array_agg(countsandareas))[1] = 0 AND 
       (array_agg(countsandareas))[2] = 66 AND 
       (array_agg(countsandareas))[3] = 10 AND 
       (array_agg(query))[1]::text = 'SELECT * FROM public.test_geotablesummary WHERE ST_NPoints(geom) = 0;' AND 
       (array_agg(query))[2]::text = 'SELECT * FROM public.test_geotablesummary WHERE ST_NPoints(geom) = 66;' AND 
       (array_agg(query))[3]::text = 'No usefull query' passed
FROM ST_GeoTableSummary('public', 'test_geotablesummary', 'geom', 'id')
WHERE summary = '6'
---------------------------------------------------------
UNION ALL
SELECT '17.10'::text number,
       'ST_GeoTableSummary'::text function_tested,
       'Vertex histogram results'::text description,
       (array_agg(countsandareas))[1] = 1 AND 
       (array_agg(countsandareas))[2] = 9 AND 
       (array_agg(countsandareas))[3] = 0 AND 
       (array_agg(countsandareas))[4] = 0 AND 
       (array_agg(countsandareas))[5] = 0 AND 
       (array_agg(countsandareas))[6] = 0 AND 
       (array_agg(countsandareas))[7] = 1 AND 
       (array_agg(countsandareas))[8] = 0 AND 
       (array_agg(countsandareas))[9] = 0 AND 
       (array_agg(countsandareas))[10] = 0 AND 
       (array_agg(countsandareas))[11] = 1 AND 
       (array_agg(query))[1]::text = 'SELECT *, ST_NPoints(geom) nbpoints FROM public.test_geotablesummary WHERE ST_NPoints(geom) IS NULL;' AND 
       (array_agg(query))[2]::text = 'SELECT *, ST_NPoints(geom) nbpoints FROM public.test_geotablesummary WHERE ST_NPoints(geom) >= 0 AND ST_NPoints(geom) < 7 ORDER BY ST_NPoints(geom) DESC;' AND 
       (array_agg(query))[3]::text = 'SELECT *, ST_NPoints(geom) nbpoints FROM public.test_geotablesummary WHERE ST_NPoints(geom) >= 7 AND ST_NPoints(geom) < 13 ORDER BY ST_NPoints(geom) DESC;' AND 
       (array_agg(query))[4]::text = 'SELECT *, ST_NPoints(geom) nbpoints FROM public.test_geotablesummary WHERE ST_NPoints(geom) >= 13 AND ST_NPoints(geom) < 20 ORDER BY ST_NPoints(geom) DESC;' AND 
       (array_agg(query))[5]::text = 'SELECT *, ST_NPoints(geom) nbpoints FROM public.test_geotablesummary WHERE ST_NPoints(geom) >= 20 AND ST_NPoints(geom) < 26 ORDER BY ST_NPoints(geom) DESC;' AND 
       (array_agg(query))[6]::text = 'SELECT *, ST_NPoints(geom) nbpoints FROM public.test_geotablesummary WHERE ST_NPoints(geom) >= 26 AND ST_NPoints(geom) < 33 ORDER BY ST_NPoints(geom) DESC;' AND 
       (array_agg(query))[7]::text = 'SELECT *, ST_NPoints(geom) nbpoints FROM public.test_geotablesummary WHERE ST_NPoints(geom) >= 33 AND ST_NPoints(geom) < 40 ORDER BY ST_NPoints(geom) DESC;' AND 
       (array_agg(query))[8]::text = 'SELECT *, ST_NPoints(geom) nbpoints FROM public.test_geotablesummary WHERE ST_NPoints(geom) >= 40 AND ST_NPoints(geom) < 46 ORDER BY ST_NPoints(geom) DESC;' AND 
       (array_agg(query))[9]::text = 'SELECT *, ST_NPoints(geom) nbpoints FROM public.test_geotablesummary WHERE ST_NPoints(geom) >= 46 AND ST_NPoints(geom) < 53 ORDER BY ST_NPoints(geom) DESC;' AND 
       (array_agg(query))[10]::text = 'SELECT *, ST_NPoints(geom) nbpoints FROM public.test_geotablesummary WHERE ST_NPoints(geom) >= 53 AND ST_NPoints(geom) < 59 ORDER BY ST_NPoints(geom) DESC;' AND 
       (array_agg(query))[11]::text = 'SELECT *, ST_NPoints(geom) nbpoints FROM public.test_geotablesummary WHERE ST_NPoints(geom) >= 59 AND ST_NPoints(geom) <= 66 ORDER BY ST_NPoints(geom) DESC;' passed
FROM ST_GeoTableSummary('public', 'test_geotablesummary', 'geom', 'id')
WHERE summary = '7'
---------------------------------------------------------
UNION ALL
SELECT '17.11'::text number,
       'ST_GeoTableSummary'::text function_tested,
       'Area statistics results'::text description,
       (array_agg(countsandareas))[1] = 0 AND 
       ((array_agg(countsandareas))[2]*100000)::int = 312145 AND 
       ((array_agg(countsandareas))[3]*100000)::int = 56470 AND 
       (array_agg(query))[1]::text = 'SELECT * FROM public.test_geotablesummary WHERE ST_Area(geom) < 0 + 0.000000001;' AND 
       (array_agg(query))[2]::text = 'SELECT * FROM public.test_geotablesummary WHERE ST_Area(geom) > 3.12144515225805 - 0.000000001 AND ST_Area(geom) < 3.12144515225805 + 0.000000001;' AND 
       (array_agg(query))[3]::text = 'No usefull query' passed
FROM ST_GeoTableSummary('public', 'test_geotablesummary', 'geom', 'id')
WHERE summary = '8'
---------------------------------------------------------
UNION ALL
SELECT '17.12'::text number,
       'ST_GeoTableSummary'::text function_tested,
       'Area histogram results'::text description,
       (array_agg(idsandtypes))[1] = 'NULL' AND 
       (array_agg(idsandtypes))[2] = '[0 - 0.31214451522580527[' AND 
       (array_agg(idsandtypes))[3] = '[0.31214451522580527 - 0.62428903045161055[' AND 
       (array_agg(idsandtypes))[4] = '[0.62428903045161055 - 0.93643354567741588[' AND 
       (array_agg(idsandtypes))[5] = '[0.93643354567741588 - 1.2485780609032211[' AND 
       (array_agg(idsandtypes))[6] = '[1.2485780609032211 - 1.5607225761290264[' AND 
       (array_agg(idsandtypes))[7] = '[1.5607225761290264 - 1.8728670913548318[' AND 
       (array_agg(idsandtypes))[8] = '[1.8728670913548318 - 2.1850116065806371[' AND 
       (array_agg(idsandtypes))[9] = '[2.1850116065806371 - 2.4971561218064422[' AND 
       (array_agg(idsandtypes))[10] = '[2.4971561218064422 - 2.8093006370322477[' AND 
       (array_agg(idsandtypes))[11] = '[2.8093006370322477 - 3.1214451522580529]' AND 
       (array_agg(countsandareas))[1] = 1 AND 
       (array_agg(countsandareas))[2] = 9 AND 
       (array_agg(countsandareas))[3] = 0 AND 
       (array_agg(countsandareas))[4] = 0 AND 
       (array_agg(countsandareas))[5] = 0 AND 
       (array_agg(countsandareas))[6] = 0 AND 
       (array_agg(countsandareas))[7] = 0 AND 
       (array_agg(countsandareas))[8] = 0 AND 
       (array_agg(countsandareas))[9] = 0 AND 
       (array_agg(countsandareas))[10] = 0 AND 
       (array_agg(countsandareas))[11] = 2 AND 
       (array_agg(query))[1]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) IS NULL;' AND 
       (array_agg(query))[2]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) >= 0 AND ST_Area(geom) < 0.31214451522580527 ORDER BY ST_Area(geom) DESC;' AND 
       (array_agg(query))[3]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) >= 0.31214451522580527 AND ST_Area(geom) < 0.62428903045161055 ORDER BY ST_Area(geom) DESC;' AND 
       (array_agg(query))[4]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) >= 0.62428903045161055 AND ST_Area(geom) < 0.93643354567741588 ORDER BY ST_Area(geom) DESC;' AND 
       (array_agg(query))[5]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) >= 0.93643354567741588 AND ST_Area(geom) < 1.2485780609032211 ORDER BY ST_Area(geom) DESC;' AND 
       (array_agg(query))[6]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) >= 1.2485780609032211 AND ST_Area(geom) < 1.5607225761290264 ORDER BY ST_Area(geom) DESC;' AND 
       (array_agg(query))[7]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) >= 1.5607225761290264 AND ST_Area(geom) < 1.8728670913548318 ORDER BY ST_Area(geom) DESC;' AND 
       (array_agg(query))[8]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) >= 1.8728670913548318 AND ST_Area(geom) < 2.1850116065806371 ORDER BY ST_Area(geom) DESC;' AND 
       (array_agg(query))[9]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) >= 2.1850116065806371 AND ST_Area(geom) < 2.4971561218064422 ORDER BY ST_Area(geom) DESC;' AND 
       (array_agg(query))[10]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) >= 2.4971561218064422 AND ST_Area(geom) < 2.8093006370322477 ORDER BY ST_Area(geom) DESC;' AND 
       (array_agg(query))[11]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) >= 2.8093006370322477 AND ST_Area(geom) <= 3.1214451522580529 ORDER BY ST_Area(geom) DESC;' passed
FROM ST_GeoTableSummary('public', 'test_geotablesummary', 'geom', 'id')
WHERE summary = '9'
---------------------------------------------------------
UNION ALL
SELECT '17.13'::text number,
       'ST_GeoTableSummary'::text function_tested,
       'Small area count results'::text description,
       (array_agg(idsandtypes))[1] = 'NULL' AND 
       (array_agg(idsandtypes))[2] = '[0]' AND 
       (array_agg(idsandtypes))[3] = ']0 - 0.0000001[' AND 
       (array_agg(idsandtypes))[4] = '[0.0000001 - 0.000001[' AND 
       (array_agg(idsandtypes))[5] = '[0.000001 - 0.00001[' AND 
       (array_agg(idsandtypes))[6] = '[0.00001 - 0.0001[' AND 
       (array_agg(idsandtypes))[7] = '[0.0001 - 0.001[' AND 
       (array_agg(idsandtypes))[8] = '[0.001 - 0.01[' AND 
       (array_agg(idsandtypes))[9] = '[0.01 - 0.1[' AND 
       (array_agg(countsandareas))[1] = 1 AND 
       (array_agg(countsandareas))[2] = 9 AND 
       (array_agg(countsandareas))[3] = 0 AND 
       (array_agg(countsandareas))[4] = 0 AND 
       (array_agg(countsandareas))[5] = 0 AND 
       (array_agg(countsandareas))[6] = 0 AND 
       (array_agg(countsandareas))[7] = 0 AND 
       (array_agg(countsandareas))[8] = 0 AND 
       (array_agg(countsandareas))[9] = 0 AND  
       (array_agg(query))[1]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) IS NULL;' AND 
       (array_agg(query))[2]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) = 0;' AND 
       (array_agg(query))[3]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) > 0 AND ST_Area(geom) < 0.0000001 ORDER BY ST_Area(geom) DESC;' AND 
       (array_agg(query))[4]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) >= 0.0000001 AND ST_Area(geom) < 0.000001 ORDER BY ST_Area(geom) DESC;' AND 
       (array_agg(query))[5]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) >= 0.000001 AND ST_Area(geom) < 0.00001 ORDER BY ST_Area(geom) DESC;' AND 
       (array_agg(query))[6]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) >= 0.00001 AND ST_Area(geom) < 0.0001 ORDER BY ST_Area(geom) DESC;' AND 
       (array_agg(query))[7]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) >= 0.0001 AND ST_Area(geom) < 0.001 ORDER BY ST_Area(geom) DESC;' AND 
       (array_agg(query))[8]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) >= 0.001 AND ST_Area(geom) < 0.01 ORDER BY ST_Area(geom) DESC;' AND 
       (array_agg(query))[9]::text = 'SELECT *, ST_Area(geom) area FROM public.test_geotablesummary WHERE ST_Area(geom) >= 0.01 AND ST_Area(geom) < 0.1 ORDER BY ST_Area(geom) DESC;' passed
FROM ST_GeoTableSummary('public', 'test_geotablesummary', 'geom', 'id', null, 'SACOUNT')
WHERE summary = '10'
---------------------------------------------------------
UNION ALL
SELECT '17.14'::text number,
       'ST_GeoTableSummary'::text function_tested,
       'dosummary and skipsummary passed as text'::text description,
       (array_agg(idsandtypes))[1] = '' AND 
       (array_agg(idsandtypes))[2] = 'SKIPPED' AND 
       (array_agg(idsandtypes))[3] != 'SKIPPED' AND 
       (array_agg(idsandtypes))[6] = 'SKIPPED' AND 
       (array_agg(idsandtypes))[7] = 'SKIPPED' AND 
       (array_agg(idsandtypes))[8] = 'SKIPPED' AND 
       (array_agg(idsandtypes))[9] = 'STATISTIC' AND 
       (array_agg(idsandtypes))[10] = 'MIN number of vertexes' AND 
       (array_agg(idsandtypes))[11] = 'MAX number of vertexes' AND 
       (array_agg(idsandtypes))[12] = 'MEAN number of vertexes' AND 
       (array_agg(idsandtypes))[13] = 'SKIPPED' AND 
       (array_agg(idsandtypes))[14] = 'STATISTIC' AND 
       (array_agg(idsandtypes))[15] = 'MIN area' AND 
       (array_agg(idsandtypes))[16] = 'MAX area' AND 
       (array_agg(idsandtypes))[17] = 'MEAN area' AND 
       (array_agg(idsandtypes))[18] = 'SKIPPED' AND 
       (array_agg(idsandtypes))[19] = 'SKIPPED'
FROM ST_GeoTableSummary('public', 'test_geotablesummary', 'geom', 'id', null, 's1, GDUP, VERTX, s8', 's1')

---------------------------------------------------------------------------------------------------------
UNION ALL
SELECT '17.15'::text number,
       'ST_GeoTableSummary'::text function_tested,
       'Whereclause parameter'::text description,
       sum(countsandareas) = 34
FROM (SELECT * FROM (SELECT (ST_GeoTableSummary('public', 'test_geotablesummary', 'geom', 'id', null, 'all', 'ovl', 'id1 < 10')).*) foo WHERE summary = '5' OR summary = '7' OR summary = '9' OR summary = '10') foo

---------------------------------------------------------------------------------------------------------
UNION ALL
SELECT '17.16'::text number,
       'ST_GeoTableSummary'::text function_tested,
       'where clause resulting in no rows'::text description,
       sum(countsandareas) = 0
FROM (SELECT * FROM (SELECT (ST_GeoTableSummary('public', 'test_geotablesummary', 'geom', null, null, 'all', null, 'id1 > 100')).*) foo) foo

---------------------------------------------------------
UNION ALL
SELECT '17.17'::text number,
       'ST_GeoTableSummary'::text function_tested,
       'gaps summary results'::text description,
       idsandtypes = '1' passed
FROM ST_GeoTableSummary('public', 'test_geotablesummary', 'geom', 'id', null, ARRAY['GAPS'])
WHERE summary = '4'
---------------------------------------------------------
-- Test 18 - ST_SplitByGrid
---------------------------------------------------------

UNION ALL
SELECT '18.1'::text number,
       'ST_SplitByGrid'::text function_tested,
       'Basic test'::text description,
       ST_collect(geom) = '01060000001200000001030000000100000004000000000000000000E03FABAAAAAAAAAAEA3F0000000000000000000000000000F03F000000000000E03F000000000000F03F000000000000E03FABAAAAAAAAAAEA3F010300000001000000040000000000000000000000000000000000F03F000000000000E03FABAAAAAAAAAAF23F000000000000E03F000000000000F03F0000000000000000000000000000F03F01030000000100000005000000000000000000F03F555555555555E53F000000000000E03FABAAAAAAAAAAEA3F000000000000E03F000000000000F03F000000000000F03F000000000000F03F000000000000F03F555555555555E53F01030000000100000005000000000000000000E03FABAAAAAAAAAAF23F000000000000F03F555555555555F53F000000000000F03F000000000000F03F000000000000E03F000000000000F03F000000000000E03FABAAAAAAAAAAF23F01030000000100000005000000000000000000F83F000000000000E03F000000000000F03F555555555555E53F000000000000F03F000000000000F03F000000000000F83F000000000000F03F000000000000F83F000000000000E03F01030000000100000005000000000000000000F03F555555555555F53F000000000000F83F000000000000F83F000000000000F83F000000000000F03F000000000000F03F000000000000F03F000000000000F03F555555555555F53F010300000001000000040000000000000000000040555555555555D53F000000000000F83F000000000000E03F0000000000000040000000000000E03F0000000000000040555555555555D53F01030000000100000005000000000000000000F83F000000000000E03F000000000000F83F000000000000F03F0000000000000040000000000000F03F0000000000000040000000000000E03F000000000000F83F000000000000E03F01030000000100000005000000000000000000F83F000000000000F03F000000000000F83F000000000000F83F0000000000000040000000000000F83F0000000000000040000000000000F03F000000000000F83F000000000000F03F01030000000100000004000000000000000000F83F000000000000F83F0000000000000040ABAAAAAAAAAAFA3F0000000000000040000000000000F83F000000000000F83F000000000000F83F010300000001000000050000000000000000000440565555555555C53F0000000000000040555555555555D53F0000000000000040000000000000E03F0000000000000440000000000000E03F0000000000000440565555555555C53F010300000001000000050000000000000000000040000000000000E03F0000000000000040000000000000F03F0000000000000440000000000000F03F0000000000000440000000000000E03F0000000000000040000000000000E03F010300000001000000050000000000000000000040000000000000F03F0000000000000040000000000000F83F0000000000000440000000000000F83F0000000000000440000000000000F03F0000000000000040000000000000F03F010300000001000000050000000000000000000040ABAAAAAAAAAAFA3F0000000000000440555555555555FD3F0000000000000440000000000000F83F0000000000000040000000000000F83F0000000000000040ABAAAAAAAAAAFA3F010300000001000000050000000000000000000840000000000000E03F000000000000084000000000000000000000000000000440565555555555C53F0000000000000440000000000000E03F0000000000000840000000000000E03F010300000001000000050000000000000000000840000000000000F03F0000000000000840000000000000E03F0000000000000440000000000000E03F0000000000000440000000000000F03F0000000000000840000000000000F03F010300000001000000050000000000000000000840000000000000F83F0000000000000840000000000000F03F0000000000000440000000000000F03F0000000000000440000000000000F83F0000000000000840000000000000F83F010300000001000000050000000000000000000440555555555555FD3F000000000000084000000000000000400000000000000840000000000000F83F0000000000000440000000000000F83F0000000000000440555555555555FD3F' AND
       sum(tid) = 720000045 AND 
       sum(x) = 72 AND 
       sum(y) = 45
FROM (SELECT (ST_SplitByGrid(ST_GeomFromText('MULTIPOLYGON(((0 1, 3 2, 3 0, 0 1)))'), 0.5)).*) foo

---------------------------------------------------------
-- Test 19 - ST_Histogram
---------------------------------------------------------

UNION ALL
SELECT '19.1'::text number,
       'ST_Histogram'::text function_tested,
       'Basic test 1 with integer values'::text description,
       (array_agg(intervals))[1] = 'NULL' AND 
       (array_agg(intervals))[2] = '[1 - 2[' AND 
       (array_agg(intervals))[3] = '[2 - 3[' AND 
       (array_agg(intervals))[4] = '[3 - 4[' AND 
       (array_agg(intervals))[5] = '[4 - 5[' AND 
       (array_agg(intervals))[6] = '[5 - 6[' AND 
       (array_agg(intervals))[7] = '[6 - 7[' AND 
       (array_agg(intervals))[8] = '[7 - 8[' AND 
       (array_agg(intervals))[9] = '[8 - 9[' AND 
       (array_agg(intervals))[10] = '[9 - 10[' AND 
       (array_agg(intervals))[11] = '[10 - 11]' AND 
       (array_agg(cnt))[1] = 0 AND 
       (array_agg(cnt))[2] = 1 AND 
       (array_agg(cnt))[3] = 1 AND 
       (array_agg(cnt))[4] = 1 AND 
       (array_agg(cnt))[5] = 1 AND 
       (array_agg(cnt))[6] = 1 AND 
       (array_agg(cnt))[7] = 1 AND 
       (array_agg(cnt))[8] = 1 AND 
       (array_agg(cnt))[9] = 1 AND 
       (array_agg(cnt))[10] = 1 AND 
       (array_agg(cnt))[11] = 3 AND 
       (array_agg(query))[1]::text = 'SELECT * FROM public.test_geotablesummary WHERE id1 IS NULL;' AND 
       (array_agg(query))[2]::text = 'SELECT * FROM public.test_geotablesummary WHERE id1 >= 1 AND id1 < 2 ORDER BY id1;' AND 
       (array_agg(query))[3]::text = 'SELECT * FROM public.test_geotablesummary WHERE id1 >= 2 AND id1 < 3 ORDER BY id1;' AND 
       (array_agg(query))[4]::text = 'SELECT * FROM public.test_geotablesummary WHERE id1 >= 3 AND id1 < 4 ORDER BY id1;' AND 
       (array_agg(query))[5]::text = 'SELECT * FROM public.test_geotablesummary WHERE id1 >= 4 AND id1 < 5 ORDER BY id1;' AND 
       (array_agg(query))[6]::text = 'SELECT * FROM public.test_geotablesummary WHERE id1 >= 5 AND id1 < 6 ORDER BY id1;' AND 
       (array_agg(query))[7]::text = 'SELECT * FROM public.test_geotablesummary WHERE id1 >= 6 AND id1 < 7 ORDER BY id1;' AND 
       (array_agg(query))[8]::text = 'SELECT * FROM public.test_geotablesummary WHERE id1 >= 7 AND id1 < 8 ORDER BY id1;' AND 
       (array_agg(query))[9]::text = 'SELECT * FROM public.test_geotablesummary WHERE id1 >= 8 AND id1 < 9 ORDER BY id1;' AND 
       (array_agg(query))[10]::text = 'SELECT * FROM public.test_geotablesummary WHERE id1 >= 9 AND id1 < 10 ORDER BY id1;' AND 
       (array_agg(query))[11]::text = 'SELECT * FROM public.test_geotablesummary WHERE id1 >= 10 AND id1 <= 11 ORDER BY id1;' passed
FROM ST_Histogram('public', 'test_geotablesummary', 'id1')
---------------------------------------------------------

UNION ALL
SELECT '19.2'::text number,
       'ST_Histogram'::text function_tested,
       'Basic test 2 with integer values'::text description,
       (array_agg(intervals))[1] = 'NULL' AND 
       (array_agg(intervals))[2] = '[1 - 2.1[' AND 
       (array_agg(intervals))[3] = '[2.1 - 3.2[' AND 
       (array_agg(intervals))[4] = '[3.2 - 4.3[' AND 
       (array_agg(intervals))[5] = '[4.3 - 5.4[' AND 
       (array_agg(intervals))[6] = '[5.4 - 6.5[' AND 
       (array_agg(intervals))[7] = '[6.5 - 7.6[' AND 
       (array_agg(intervals))[8] = '[7.6 - 8.7[' AND 
       (array_agg(intervals))[9] = '[8.7 - 9.8[' AND 
       (array_agg(intervals))[10] = '[9.8 - 10.9[' AND 
       (array_agg(intervals))[11] = '[10.9 - 12]' AND 
       (array_agg(cnt))[1] = 0 AND 
       (array_agg(cnt))[2] = 2 AND 
       (array_agg(cnt))[3] = 1 AND 
       (array_agg(cnt))[4] = 1 AND 
       (array_agg(cnt))[5] = 1 AND 
       (array_agg(cnt))[6] = 1 AND 
       (array_agg(cnt))[7] = 1 AND 
       (array_agg(cnt))[8] = 1 AND 
       (array_agg(cnt))[9] = 1 AND 
       (array_agg(cnt))[10] = 1 AND 
       (array_agg(cnt))[11] = 2 AND 
       (array_agg(query))[1]::text = 'SELECT * FROM public.test_geotablesummary WHERE id2 IS NULL;' AND 
       (array_agg(query))[2]::text = 'SELECT * FROM public.test_geotablesummary WHERE id2 >= 1 AND id2 < 2.1 ORDER BY id2;' AND 
       (array_agg(query))[3]::text = 'SELECT * FROM public.test_geotablesummary WHERE id2 >= 2.1 AND id2 < 3.2 ORDER BY id2;' AND 
       (array_agg(query))[4]::text = 'SELECT * FROM public.test_geotablesummary WHERE id2 >= 3.2 AND id2 < 4.3 ORDER BY id2;' AND 
       (array_agg(query))[5]::text = 'SELECT * FROM public.test_geotablesummary WHERE id2 >= 4.3 AND id2 < 5.4 ORDER BY id2;' AND 
       (array_agg(query))[6]::text = 'SELECT * FROM public.test_geotablesummary WHERE id2 >= 5.4 AND id2 < 6.5 ORDER BY id2;' AND 
       (array_agg(query))[7]::text = 'SELECT * FROM public.test_geotablesummary WHERE id2 >= 6.5 AND id2 < 7.6 ORDER BY id2;' AND 
       (array_agg(query))[8]::text = 'SELECT * FROM public.test_geotablesummary WHERE id2 >= 7.6 AND id2 < 8.7 ORDER BY id2;' AND 
       (array_agg(query))[9]::text = 'SELECT * FROM public.test_geotablesummary WHERE id2 >= 8.7 AND id2 < 9.8 ORDER BY id2;' AND 
       (array_agg(query))[10]::text = 'SELECT * FROM public.test_geotablesummary WHERE id2 >= 9.8 AND id2 < 10.9 ORDER BY id2;' AND 
       (array_agg(query))[11]::text = 'SELECT * FROM public.test_geotablesummary WHERE id2 >= 10.9 AND id2 <= 12 ORDER BY id2;' passed
FROM ST_Histogram('public', 'test_geotablesummary', 'id2')
---------------------------------------------------------

UNION ALL
SELECT '19.3'::text number,
       'ST_Histogram'::text function_tested,
       'Basic test with float values'::text description,
       (array_agg(intervals))[1] = 'NULL' AND 
       (array_agg(intervals))[2] = '[0.025574925821274519 - 0.26533543120604008[' AND 
       (array_agg(intervals))[3] = '[0.26533543120604008 - 0.50509593659080565[' AND 
       (array_agg(intervals))[4] = '[0.50509593659080565 - 0.74485644197557122[' AND 
       (array_agg(intervals))[5] = '[0.74485644197557122 - 0.98461694736033678]' AND 
       (array_agg(cnt))[1] = 0 AND 
       (array_agg(cnt))[2] = 23 AND 
       (array_agg(cnt))[3] = 23 AND 
       (array_agg(cnt))[4] = 22 AND 
       (array_agg(cnt))[5] = 32 AND 
       (array_agg(query))[1]::text = 'SELECT * FROM public.test_histogram WHERE r1 IS NULL;' AND 
       (array_agg(query))[2]::text = 'SELECT * FROM public.test_histogram WHERE r1 >= 0.025574925821274519 AND r1 < 0.26533543120604008 ORDER BY r1;' AND 
       (array_agg(query))[3]::text = 'SELECT * FROM public.test_histogram WHERE r1 >= 0.26533543120604008 AND r1 < 0.50509593659080565 ORDER BY r1;' AND 
       (array_agg(query))[4]::text = 'SELECT * FROM public.test_histogram WHERE r1 >= 0.50509593659080565 AND r1 < 0.74485644197557122 ORDER BY r1;' AND 
       (array_agg(query))[5]::text = 'SELECT * FROM public.test_histogram WHERE r1 >= 0.74485644197557122 AND r1 <= 0.98461694736033678 ORDER BY r1;' passed
FROM ST_Histogram('public', 'test_histogram', 'r1', 4)
---------------------------------------------------------

UNION ALL
SELECT '19.4'::text number,
       'ST_Histogram'::text function_tested,
       'Basic test with very small float values'::text description,
       (array_agg(intervals))[1] = 'NULL' AND 
       (array_agg(intervals))[2] = '[2.5574925821274518e-009 - 2.6533543120604006e-008[' AND 
       (array_agg(intervals))[3] = '[2.6533543120604006e-008 - 5.0509593659080564e-008[' AND 
       (array_agg(intervals))[4] = '[5.0509593659080564e-008 - 7.4485644197557122e-008[' AND 
       (array_agg(intervals))[5] = '[7.4485644197557122e-008 - 9.8461694736033674e-008]' AND 
       (array_agg(cnt))[1] = 0 AND 
       (array_agg(cnt))[2] = 23 AND 
       (array_agg(cnt))[3] = 23 AND 
       (array_agg(cnt))[4] = 22 AND 
       (array_agg(cnt))[5] = 32 AND 
       (array_agg(query))[1]::text = 'SELECT * FROM public.test_histogram WHERE r2 IS NULL;' AND 
       (array_agg(query))[2]::text = 'SELECT * FROM public.test_histogram WHERE r2 >= 2.5574925821274518e-009 AND r2 < 2.6533543120604006e-008 ORDER BY r2;' AND 
       (array_agg(query))[3]::text = 'SELECT * FROM public.test_histogram WHERE r2 >= 2.6533543120604006e-008 AND r2 < 5.0509593659080564e-008 ORDER BY r2;' AND 
       (array_agg(query))[4]::text = 'SELECT * FROM public.test_histogram WHERE r2 >= 5.0509593659080564e-008 AND r2 < 7.4485644197557122e-008 ORDER BY r2;' AND 
       (array_agg(query))[5]::text = 'SELECT * FROM public.test_histogram WHERE r2 >= 7.4485644197557122e-008 AND r2 <= 9.8461694736033674e-008 ORDER BY r2;' passed
FROM ST_Histogram('public', 'test_histogram', 'r2', 4)
---------------------------------------------------------

UNION ALL
SELECT '19.5'::text number,
       'ST_Histogram'::text function_tested,
       'Basic test with three values'::text description,
       (array_agg(intervals))[1] = 'NULL' AND 
       (array_agg(intervals))[2] = '[1 - 2[' AND 
       (array_agg(intervals))[3] = '[2 - 3]' AND 
       (array_agg(cnt))[1] = 0 AND 
       (array_agg(cnt))[2] = 1 AND 
       (array_agg(cnt))[3] = 2 AND 
       (array_agg(query))[1]::text = 'SELECT * FROM public.test_histogram WHERE id IS NULL AND (id < 4);' AND 
       (array_agg(query))[2]::text = 'SELECT * FROM public.test_histogram WHERE id >= 1 AND id < 2 AND (id < 4) ORDER BY id;' AND 
       (array_agg(query))[3]::text = 'SELECT * FROM public.test_histogram WHERE id >= 2 AND id <= 3 AND (id < 4) ORDER BY id;' passed
FROM ST_Histogram('public', 'test_histogram', 'id', 2, 'id < 4')
---------------------------------------------------------

UNION ALL
SELECT '19.6'::text number,
       'ST_Histogram'::text function_tested,
       'Basic test with three null values'::text description,
       (array_agg(intervals))[1] = 'NULL' AND 
       (array_agg(cnt))[1] = 2 AND 
       (array_agg(query))[1]::text = 'SELECT * FROM public.test_histogram WHERE id2 IS NULL AND (id < 3);' passed
FROM ST_Histogram('public', 'test_histogram', 'id2', 2, 'id < 3')
---------------------------------------------------------

UNION ALL
SELECT '19.7'::text number,
       'ST_Histogram'::text function_tested,
       'max - min = 0'::text description,
       (array_agg(intervals))[1] = 'NULL' AND 
       (array_agg(intervals))[2] = '[11 - 11]' AND 
       (array_agg(cnt))[1] = 0 AND 
       (array_agg(cnt))[2] = 2 AND 
       (array_agg(query))[1]::text = 'SELECT * FROM public.test_geotablesummary WHERE id1 IS NULL AND (id1 > 10);' AND 
       (array_agg(query))[2]::text = 'SELECT * FROM public.test_geotablesummary WHERE id1 >= 11 AND id1 <= 11 AND (id1 > 10) ORDER BY id1;'  passed
FROM ST_Histogram('public', 'test_geotablesummary', 'id1', 10, 'id1 > 10')
---------------------------------------------------------

UNION ALL
SELECT '19.8'::text number,
       'ST_Histogram'::text function_tested,
       'intervals < 0'::text description,
       count(*) = 0 passed
FROM ST_Histogram('public', 'test_histogram', 'id', -4)
---------------------------------------------------------
UNION ALL
SELECT '19.9'::text number,
       'ST_Histogram'::text function_tested,
       'intervals < 0'::text description,
       count(*) = 0 passed
FROM ST_Histogram('public', 'test_histogram', 'id', -4)
---------------------------------------------------------
) b 
ON (a.function_tested = b.function_tested AND (regexp_split_to_array(number, '\.'))[2] = min_num) 
ORDER BY maj_num::int, min_num::int
-- This last line has to be commented out, with the line at the beginning,
-- to display only failing tests...
--) foo WHERE NOT passed;