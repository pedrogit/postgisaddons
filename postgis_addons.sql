-------------------------------------------------------------------------------
-- PostGIS PL/pgSQL Add-ons - Main installation file
-- Version 1.10 for PostGIS 2.1.x and PostgreSQL 9.x
-- http://github.com/pedrogit/postgisaddons
-- 
-- The PostGIS add-ons attempt to gather, in a single .sql file, useful and 
-- generic user contributed PL/pgSQL functions and to provide a fast and Agile 
-- release cycle. Files will be tagged with an incremental version number
-- for every significant change or addition. They should ALWAYS be left in a 
-- stable, installable and tested state.
--
-- Signatures and return values for existing functions should not change from 
-- minor revision to minor revision. New functions might be added though.
--
-- PostGIS PL/pgSQL Add-ons tries to make life as easy as possible for users
-- wishing to contribute their functions. This is why it limits itself to 
-- only three files: the main function executable file, a test file and an 
-- unsinstall file. All function are documented inside the main function file 
-- (this file). 
--
-- To be included, a function:
-- 
--   - Must be of generic enough to be useful to many PostGIS users.
--   - Must be documented according to the rules defined in this file.
--   - Must be accompagned by a series of test in the postgis_addons_test.sql file.
--   - Must have a drop statement in the postgis_addons_uninstall.sql file.
--   - Must be indented similarly to the already existing functions (4 spaces, no tabs).
-- 
-- Companion files
-- 
--   - postgis_addons.sql             Main redistributable file containing all the 
--                                    functions.
--   - postgis_addons_uninstall.sql   Uninstallation file.
--   - postgis_addons_test.sql        Self contained test file to be executed after  
--                                    installation and before any commit of the main 
--                                    file.
-- 
-------------------------------------------------------------------------------
-- Documentation
-- 
-- Each function must be documented directly in the postgis_addons.sql file just 
-- before the definition of the function.
-- 
-- Mandatory documentation elements for each function:
-- 
--   - Function name,
--   - Parameters listing and description of each parameter,
--   - Description,
--   - A self contained example,
--   - A typical, not necessarily self contained, example,
--   - Links to more examples on the web (blog post, etc...),
--   - Authors names with emails,
--   - Date and version of availability (date of inclusion in PostGIS Add-ons).
--
-------------------------------------------------------------------------------
-- Function list
--
--   ST_DeleteBand - Removes a band from a raster. Band number starts at 1.
--
--   ST_CreateIndexRaster - Creates a new raster as an index grid.
--
--   ST_RandomPoints - Generates points located randomly inside a geometry.
--
--   ST_ColumnExists - Return true if a column exist in a table.
--
--   ST_AddUniqueID - Add a column to a table and fill it with a unique integer 
--                    starting at 1.
--
--   ST_AreaWeightedSummaryStats - Aggregate function computing statistics on a 
--                                 series of intersected values weighted by the 
--                                 area of the corresponding geometry.
--
--   ST_SummaryStatsAgg - Aggregate function computing statistics on a series of 
--                        rasters generally clipped by a geometry.
--
-------------------------------------------------------------------------------
-- Begin Function Definitions...
-------------------------------------------------------------------------------
-- ST_DeleteBand
--
--   rast raster - Raster in which to remove a band.
--   band int    - Number of the band to remove.
--
--   RETURNS raster
--
-- Removes a band from a raster. Band number starts at 1.
-----------------------------------------------------------
-- Self contained example:
--
-- SELECT ST_NumBands(ST_DeleteBand(rast, 2)) nb1, ST_NumBands(rast) nb2
-- FROM (SELECT ST_AddBand(ST_MakeEmptyRaster(10, 10, 0, 0, 1),
--                         ARRAY[ROW(NULL, '8BUI', 255, 0), 
--                               ROW(NULL, '16BUI', 1, 2)]::addbandarg[]) rast
--      ) foo;
--
-- Typical example removing a band from an existing raster table:
--
-- UPDATE rastertable SET rast = ST_DeleteBand(rast, 2);
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 26/09/2013 v. 1.4
-----------------------------------------------------------

-----------------------------------------------------------
CREATE OR REPLACE FUNCTION ST_DeleteBand(
    rast raster,
    band int
) 
RETURNS raster AS $$
    DECLARE
        numband int := ST_NumBands(rast);
        newrast raster := ST_MakeEmptyRaster(rast);
    BEGIN
        IF rast IS NULL THEN
            RETURN null;
        END IF;
        IF band IS NULL THEN
            RETURN rast;
        END IF;
        -- Reconstruct the raster skippind the band to delete
        FOR b IN 1..numband LOOP
            IF b != band THEN
                newrast := ST_AddBand(newrast, rast, b, NULL);
            END IF;
        END LOOP;
        RETURN newrast;
    END;
$$ LANGUAGE 'plpgsql' VOLATILE;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ST_CreateIndexRaster
--
--   rast raster          - Raster from which are copied the metadata to build the new, index raster. 
--                          Generally created from scratch with ST_MakeEmptyRaster().
--   pixeltype text       - Pixel type of the new index raster. The default is 32BUI.
--   startvalue int       - The first value assigned to the index raster. The default is 0.
--   incwithx boolean     - When true (default), indexes increase with the x raster coordinate of the pixel.
--   incwithy boolean     - When true (default), indexes increase with the y raster coordinate of the pixel.
--                          (When scaley is negative, indexes decrease with y.)
--   rowsfirst boolean    - When true (default), indexes increase vertically first, and then horizontally.
--   rowscanorder boolean - When true (default), indexes increase always in the same direction (row scan). 
--                          When false indexes increase alternatively in direction and then in the other
--                          direction (row-prime scan).
--   colinc int           - Colums increment value. Must be greater than rowinc * (ST_Height() - 1) when 
--                          columnfirst is true.
--   rowinc int           - Row increment value. Must be greater than colinc * (ST_Width() - 1) when 
--                          columnfirst is false.
--
--   RETURNS raster
--
-- Creates a new raster as an index grid.
-----------------------------------------------------------
-- Self contained example:
--
-- SELECT (gvxy).geom, (gvxy).val
-- FROM ST_PixelAsPolygons(ST_CreateIndexRaster(ST_MakeEmptyRaster(10, 10, 0, 0, 1, 1, 0, 0), '8BUI')) gvxy;
--
-- Typical example creating a z scanned raster with rows incrementing by 10 and columns incrementing by 1000:
--
-- CREATE TABLE newraster AS
-- SELECT ST_CreateIndexRaster(ST_MakeEmptyRaster(10, 10, 0, 0, 1, 1, 0, 0), '32BUI', 0, true, true, true, false, 1000, 10) rast;
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 27/09/2013 v. 1.5
-----------------------------------------------------------

-----------------------------------------------------------
CREATE OR REPLACE FUNCTION ST_CreateIndexRaster(
    rast raster, 
    pixeltype text DEFAULT '32BUI', 
    startvalue int DEFAULT 0, 
    incwithx boolean DEFAULT true, 
    incwithy boolean DEFAULT true,
    rowsfirst boolean DEFAULT true,
    rowscanorder boolean DEFAULT true,
    colinc int DEFAULT NULL,
    rowinc int DEFAULT NULL
)
RETURNS raster AS $$
    DECLARE
        newraster raster := ST_AddBand(ST_MakeEmptyRaster(rast), pixeltype);
        x int;
        y int;
        w int := ST_Width(newraster);
        h int := ST_Height(newraster);
        rowincx int := Coalesce(rowinc, w);
        colincx int := Coalesce(colinc, h);
        rowincy int := Coalesce(rowinc, 1);
        colincy int := Coalesce(colinc, 1);
        xdir int := CASE WHEN Coalesce(incwithx, true) THEN 1 ELSE w END;
        ydir int := CASE WHEN Coalesce(incwithy, true) THEN 1 ELSE h END;
        xdflag int := Coalesce(incwithx::int, 1);
        ydflag int := Coalesce(incwithy::int, 1);
        rsflag int := Coalesce(rowscanorder::int, 1);
        newstartvalue int := Coalesce(startvalue, 0);
        newrowsfirst boolean := Coalesce(rowsfirst, true);
    BEGIN
        IF newrowsfirst THEN
            IF colincx <= (h - 1) * rowincy THEN
                RAISE EXCEPTION 'Column increment (now %) must be greater than the number of index on one column (now % pixel x % = %)...', colincx, h - 1, rowincy, (h - 1) * rowincy;
            END IF;
            --RAISE NOTICE 'abs([rast.x] - %) * % + abs([rast.y] - (% ^ ((abs([rast.x] - % + 1) % 2) | % # ))::int) * % + %', xdir::text, colincx::text, h::text, xdir::text, rsflag::text, ydflag::text, rowincy::text, newstartvalue::text;
            newraster = ST_SetBandNodataValue(
                          ST_MapAlgebra(newraster, 
                                        pixeltype, 
                                        'abs([rast.x] - ' || xdir::text || ') * ' || colincx::text || 
                                        ' + abs([rast.y] - (' || h::text || ' ^ ((abs([rast.x] - ' || 
                                        xdir::text || ' + 1) % 2) | ' || rsflag::text || ' # ' || 
                                        ydflag::text || '))::int) * ' || rowincy::text || ' + ' || newstartvalue::text),
                          ST_BandNodataValue(newraster)
                        );
        ELSE
            IF rowincx <= (w - 1) * colincy THEN
                RAISE EXCEPTION 'Row increment (now %) must be greater than the number of index on one row (now % pixel x % = %)...', rowincx, w - 1, colincy, (w - 1) * colincy;
            END IF;
            newraster = ST_SetBandNodataValue(
                          ST_MapAlgebra(newraster, 
                                        pixeltype, 
                                        'abs([rast.x] - (' || w::text || ' ^ ((abs([rast.y] - ' || 
                                        ydir::text || ' + 1) % 2) | ' || rsflag::text || ' # ' || 
                                        xdflag::text || '))::int) * ' || colincy::text || ' + abs([rast.y] - ' || 
                                        ydir::text || ') * ' || rowincx::text || ' + ' || newstartvalue::text), 
                          ST_BandNodataValue(newraster)
                        );
        END IF;    
        RETURN newraster;
    END;
$$ LANGUAGE plpgsql IMMUTABLE;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ST_RandomPoints
--
--   geom geometry - Geometry in which to create the random points. Should be a polygon 
--                   or a multipolygon.
--   nb int        - Number of random points to create.
--   seed numeric  - Value between -1.0 and 1.0, inclusive, setting the seek if repeatable 
--                   results are desired. Default to null.
--
--   RETURNS set of points
--
-- Generates points located randomly inside a geometry.
-----------------------------------------------------------
-- Self contained example creating 100 points:
--
-- SELECT ST_RandomPoints(ST_GeomFromText('POLYGON((-73 48,-72 49,-71 48,-69 49,-69 48,-71 47,-73 48))'), 1000, 0.5) geom;
--
-- Typical example creating a table of 1000 points inside the union of all the geometries of a table:
--
-- CREATE TABLE random_points AS
-- SELECT ST_RandomPoints(ST_Union(geom), 1000) geom FROM geomtable;
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 10/01/2013 v. 1.6
-----------------------------------------------------------

-----------------------------------------------------------
CREATE OR REPLACE FUNCTION ST_RandomPoints(
    geom geometry, 
    nb integer,
    seed numeric DEFAULT NULL
) 
RETURNS SETOF geometry AS $$ 
    DECLARE 
        pt geometry; 
        xmin float8; 
        xmax float8; 
        ymin float8; 
        ymax float8; 
        xrange float8; 
        yrange float8; 
        srid int; 
        count integer := 0; 
        gtype text; 
    BEGIN 
        SELECT ST_GeometryType(geom) INTO gtype; 

        -- Make sure the geometry is some kind of polygon
        IF (gtype IS NULL OR (gtype != 'ST_Polygon') AND (gtype != 'ST_MultiPolygon')) THEN 
            RAISE NOTICE 'Attempting to get random points in a non polygon geometry';
            RETURN NEXT null;
            RETURN;
        END IF; 

        -- Compute the extent
        SELECT ST_XMin(geom), ST_XMax(geom), ST_YMin(geom), ST_YMax(geom), ST_SRID(geom) 
        INTO xmin, xmax, ymin, ymax, srid; 

        -- and the range of the extent
        SELECT xmax - xmin, ymax - ymin 
        INTO xrange, yrange; 

        -- Set the seed if provided
        IF seed IS NOT NULL THEN 
            PERFORM setseed(seed); 
        END IF; 

        -- Find valid points one after the other checking if they are inside the polygon
        WHILE count < nb LOOP 
            SELECT ST_SetSRID(ST_MakePoint(xmin + xrange * random(), ymin + yrange * random()), srid) 
            INTO pt; 

            IF ST_Contains(geom, pt) THEN 
                count := count + 1; 
                RETURN NEXT pt; 
            END IF; 
        END LOOP; 
        RETURN; 
    END; 
$$ LANGUAGE 'plpgsql' VOLATILE;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ST_ColumnExists
--
--   schemaname name - Name of the schema containing the table in which to check for 
--                     the existance of a column.
--   tablename name  - Name of the table in which to check for the existance of a column.
--   columnname name - Name of the column to check for the existence of.
--
--   RETURNS boolean
--
-- Return true if a column exist in a table. Mainly defined to be used by ST_AddUniqueID().
-----------------------------------------------------------
-- Self contained example:
--
-- SELECT ST_ColumnExists('public', 'spatial_ref_sys', 'srid') ;
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 10/02/2013 v. 1.7
-----------------------------------------------------------

-----------------------------------------------------------
CREATE OR REPLACE FUNCTION ST_ColumnExists(
    schemaname name, 
    tablename name, 
    columnname name
)
RETURNS BOOLEAN AS $$
    DECLARE
    BEGIN
        PERFORM 1 FROM information_schema.COLUMNS 
        WHERE table_schema=schemaname AND table_name=tablename AND column_name=columnname;
        RETURN FOUND;
    END;
$$ LANGUAGE plpgsql VOLATILE STRICT;

-----------------------------------------------------------
-- ST_ColumnExists variant defaulting to the 'public' schemaname
CREATE OR REPLACE FUNCTION ST_ColumnExists(
    tablename name, 
    columnname name
) 
RETURNS BOOLEAN AS $$
    SELECT ST_ColumnExists('public', $1, $2)
$$ LANGUAGE sql VOLATILE STRICT;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ST_AddUniqueID
--
--   schemaname name       - Name of the schema containing the table in which to check for 
--                           the existance of a column.
--   tablename name        - Name of the table in which to check for the existance of a column.
--   columnname name       - Name of the column to check for the existence of.
--   replacecolumn boolean - If set to true, drop and replace the column if it already exists.
--
--   RETURNS boolean
--
-- Add a column to a table and fill it with a unique integer starting at 1. Returns
-- true if the operation succeeded, false otherwise.
-- This is useful when you don't want to create a new table for whatever reason.
-- If you want to create a new table just:
--
-- CREATE SEQUENCE foo_id_seq;
-- CREATE TABLE newtable AS
-- SELECT *, nextval('foo_id_seq') id
-- FROM oldtable;
-----------------------------------------------------------
-- Self contained example:
--
-- SELECT ST_AddUniqueID('spatial_ref_sys', 'id', true);
-- ALTER TABLE spatial_ref_sys DROP COLUMN if;
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 10/02/2013 v. 1.7
-----------------------------------------------------------

-----------------------------------------------------------
CREATE OR REPLACE FUNCTION ST_AddUniqueID(
    schemaname name, 
    tablename name, 
    columnname name, 
    replacecolumn boolean DEFAULT false
)
RETURNS boolean AS $$
    DECLARE
        seqname text;
        fqtn text;
    BEGIN
        -- Determine the complete name of the table
        fqtn := '';
        IF length(schemaname) > 0 THEN
            fqtn := quote_ident(schemaname) || '.';
        END IF;
        fqtn := fqtn || quote_ident(tablename);

        -- Check if the requested column name already exists
        IF ST_ColumnExists(schemaname, tablename, columnname) THEN
            IF replacecolumn THEN
                EXECUTE 'ALTER TABLE ' || fqtn || ' DROP COLUMN ' || quote_ident(columnname); 
            ELSE
                RAISE NOTICE 'Column already exist. Add ''true'' as the last argument if you want to replace the column.';
                RETURN false;
            END IF;
         END IF;

         -- Create a new sequence
         seqname = schemaname || '_' || tablename || '_seq';
         EXECUTE 'DROP SEQUENCE IF EXISTS ' || quote_ident(seqname);
         EXECUTE 'CREATE SEQUENCE ' || quote_ident(seqname);

         -- Add the new column and update it with nextval('sequence')
         EXECUTE 'ALTER TABLE ' || fqtn || ' ADD COLUMN ' || quote_ident(columnname) || ' INTEGER';
         EXECUTE 'UPDATE ' || fqtn || ' SET ' || quote_ident(columnname) || ' = nextval(''' || quote_ident(seqname) || ''')';

         RETURN true;
    END;
$$ LANGUAGE 'plpgsql' VOLATILE STRICT;

-----------------------------------------------------------
-- ST_AddUniqueID variant defaulting to the 'public' schemaname
CREATE OR REPLACE FUNCTION ST_AddUniqueID(
    tablename name, 
    columnname name, 
    replacecolumn boolean DEFAULT false
) 
RETURNS BOOLEAN AS $$
    SELECT ST_AddUniqueID('public', $1, $2, $3)
$$ LANGUAGE sql VOLATILE STRICT;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ST_AreaWeightedSummaryStats
--
--   geomval - A set of geomval couple (geometry, double precision) resulting from 
--             ST_Intersection(raster, geometry).
--             A variant taking a geometry and a value also exist.
--
--   Aggregate function computing statistics on a series of intersected 
--   values weighted by the area of the corresponding geometry.
--
-- Statictics computed are:
--
--   - count          - Total number of values in the aggregate.
--   - distinctcount  - Number of different values in the aggregate.
--   - geom           - Geometric union of all the geometries involved in the aggregate.
--   - totalarea      - Total area of all the geometries involved in the aggregate (might 
--                      be greater than the area of the unioned geometry if there are 
--                      overlapping geometries).
--   - meanarea       - Mean area of the geometries involved in the aggregate.
--   - totalperimeter - Total perimeter of all the geometries involved in the aggregate.
--   - meanperimeter  - Mean perimeter of the geometries involved in the aggregate.
--   - weightedsum    - Sum of all the values involved in the aggregate multiplied by 
--                      (weighted by) the area of each geometry.
--   - weightedmean   - Weighted sum divided by the total area.
--   - maxareavalue   - Value of the geometry having the greatest area.
--   - minareavalue   - Value of the geometry having the smallest area.
--   - maxcombinedareavalue - Value of the geometry having the greatest area after 
--                            geometries with the same value have been unioned.
--   - mincombinedareavalue - Value of the geometry having the smallest area after 
--                            geometries with the same value have been unioned.
--   - sum            - Simple sum of all the values in the aggregate.
--   - man            - Simple mean of all the values in the aggregate.
--   - max            - Simple max of all the values in the aggregate.
--   - min            - Simple min of all the values in the aggregate.
--
-- This function aggregates the geometries and associated values when extracting values 
-- from one table with a table of polygons using ST_Intersection. It was specially 
-- written to be used with ST_Intersection(raster, geometry) which returns a set of 
-- (geometry, value) which have to be aggregated considering the relative importance 
-- of the area intersecting with each pixel of the raster. The function is provided 
-- only to avoid having to write the correct, often tricky, syntax to aggregate those 
-- values.
--
-- Since ST_AreaWeightedSummaryStats is an aggregate, you always have to
-- add a GROUP BY clause to tell which column to use to group the polygons parts and 
-- aggregate the corresponding values.
--
-- Note that you will always get better performance by writing yourself the right code 
-- to aggregate any of the values computed by ST_AreaWeightedSummaryStats. But for 
-- relatively small datasets, it will often be faster to use this function than to try 
-- to write the proper code. 
-- 
-- Sometimes, for tricky reasons, the function might fail when it tries to recreate 
-- the original geometry by ST_Unioning the intersected parts. When ST_Union 
-- fails, the whole ST_AreaWeightedSummaryStats function fails. If this happens, you will
-- probably have to write your own aggregating code to avoid the unioning.
--
-- This function can also be used when intersecting two geometry tables where geometries
-- are split in multiple parts.
-----------------------------------------------------------
-- Self contained example:
--
-- SELECT id,
--        (aws).count, 
--        (aws).distinctcount,
--        (aws).geom, 
--        (aws).totalarea, 
--        (aws).meanarea, 
--        (aws).totalperimeter, 
--        (aws).meanperimeter, 
--        (aws).weightedsum, 
--        (aws).weightedmean, 
--        (aws).maxareavalue, 
--        (aws).minareavalue, 
--        (aws).maxcombinedareavalue, 
--        (aws).mincombinedareavalue, 
--        (aws).sum, 
--        (aws).mean, 
--        (aws).max, 
--        (aws).min
-- FROM (SELECT ST_AreaWeightedSummaryStats((geom, val)::geomval) as aws, id
--       FROM (SELECT ST_GeomFromEWKT('POLYGON((0 0,0 10, 10 10, 10 0, 0 0))') as geom, 'a' as id, 100 as val
--             UNION ALL
--             SELECT ST_GeomFromEWKT('POLYGON((12 0,12 1, 13 1, 13 0, 12 0))') as geom, 'a' as id, 1 as val
--             UNION ALL
--             SELECT ST_GeomFromEWKT('POLYGON((10 0, 10 2, 12 2, 12 0, 10 0))') as geom, 'b' as id, 4 as val
--             UNION ALL
--             SELECT ST_GeomFromEWKT('POLYGON((10 2, 10 3, 12 3, 12 2, 10 2))') as geom, 'b' as id, 2 as val
--             UNION ALL
--             SELECT ST_GeomFromEWKT('POLYGON((10 3, 10 4, 12 4, 12 3, 10 3))') as geom, 'b' as id, 2 as val
--             UNION ALL
--             SELECT ST_GeomFromEWKT('POLYGON((10 4, 10 5, 12 5, 12 4, 10 4))') as geom, 'b' as id, 2 as val
--            ) foo1
--       GROUP BY id
--      ) foo2;
--
-- Typical exemple:
--
-- SELECT gt.id,
--        (aws).geom, 
--        (aws).totalarea, 
--        (aws).weightedmean, 
-- FROM (SELECT ST_AreaWeightedSummaryStats(gv) aws
--       FROM (SELECT ST_Intersection(rt.rast, gt.geom) gv
--             FROM rasttable rt, geomtable gt
--             WHERE ST_Intersects(rt.rast, gt.geom)
--            ) foo1
--       GROUP BY gt.id
--      ) foo2;
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 10/02/2013 v. 1.8
-----------------------------------------------------------

-----------------------------------------------------------
-- Type returned by the final _ST_AreaWeightedSummaryStats_FinalFN state function
CREATE TYPE agg_areaweightedstats AS (
    count int,
    distinctcount int,
    geom geometry,
    totalarea double precision,
    meanarea  double precision,
    totalperimeter double precision,
    meanperimeter  double precision,
    weightedsum  double precision,
    weightedmean double precision,
    maxareavalue double precision,
    minareavalue double precision,
    maxcombinedareavalue double precision, 
    mincombinedareavalue double precision, 
    sum  double precision, 
    mean double precision, 
    max  double precision, 
    min  double precision
);

-----------------------------------------------------------
-- Type returned by the _ST_AreaWeightedSummaryStats_StateFN state function
CREATE TYPE agg_areaweightedstatsstate AS (
    count int,
    distinctvalues double precision[],
    unionedgeom geometry,
    totalarea double precision,
    totalperimeter double precision,
    weightedsum  double precision,
    maxareavalue double precision[],
    minareavalue double precision[],
    combinedweightedareas double precision[], 
    sum double precision, 
    max double precision, 
    min double precision
);

-----------------------------------------------------------
-- ST_AreaWeightedSummaryStats aggregate state function
CREATE OR REPLACE FUNCTION _ST_AreaWeightedSummaryStats_StateFN(
    aws agg_areaweightedstatsstate, 
    gv geomval
)
RETURNS agg_areaweightedstatsstate  AS $$
    DECLARE
        i int;
        ret agg_areaweightedstatsstate;
        newcombinedweightedareas double precision[] := ($1).combinedweightedareas;
        newgeom geometry := ($2).geom;
        geomtype text := GeometryType(($2).geom);
    BEGIN
        -- If the geometry is a GEOMETRYCOLLECTION extract the polygon part
        IF geomtype = 'GEOMETRYCOLLECTION' THEN 
            newgeom := ST_CollectionExtract(newgeom, 3);
        END IF;
        -- Skip anything that is not a polygon
        IF newgeom IS NULL OR ST_IsEmpty(newgeom) OR geomtype = 'POINT' OR geomtype = 'LINESTRING' OR geomtype = 'MULTIPOINT' OR geomtype = 'MULTILINESTRING' THEN 
            ret := aws;
        -- At the first iteration the state parameter is always null
        ELSEIF $1 IS NULL THEN 
            ret := (1,                                 -- count
                    ARRAY[($2).val],                   -- distinctvalues
                    newgeom,                           -- unionedgeom
                    ST_Area(newgeom),                  -- totalarea
                    ST_Perimeter(newgeom),             -- totalperimeter
                    ($2).val * ST_Area(newgeom),       -- weightedsum
                    ARRAY[ST_Area(newgeom), ($2).val], -- maxareavalue
                    ARRAY[ST_Area(newgeom), ($2).val], -- minareavalue
                    ARRAY[ST_Area(newgeom)],           -- combinedweightedareas
                    ($2).val,                          -- sum
                    ($2).val,                          -- max
                    ($2).val                           -- min
                   )::agg_areaweightedstatsstate;
        ELSE
            -- Search for the new value in the array of distinct values
            SELECT n 
            FROM generate_series(1, array_length(($1).distinctvalues, 1)) n 
            WHERE (($1).distinctvalues)[n] = ($2).val 
            INTO i;

            -- If the value already exists, increment the corresponding area with the new area
            IF NOT i IS NULL THEN
                newcombinedweightedareas[i] := newcombinedweightedareas[i] + ST_Area(newgeom);
            END IF;
            ret := (($1).count + 1,                                     -- count
                    CASE WHEN i IS NULL                                 -- distinctvalues
                         THEN array_append(($1).distinctvalues, ($2).val) 
                         ELSE ($1).distinctvalues 
                    END, 
                    ST_Union(($1).unionedgeom, newgeom),                -- unionedgeom
                    ($1).totalarea + ST_Area(newgeom),                  -- totalarea
                    ($1).totalperimeter + ST_Perimeter(newgeom),        -- totalperimeter
                    ($1).weightedsum + ($2).val * ST_Area(newgeom),     -- weightedsum
                    CASE WHEN ST_Area(newgeom) > (($1).maxareavalue)[1] -- maxareavalue
                         THEN ARRAY[ST_Area(newgeom), ($2).val] 
                         ELSE ($1).maxareavalue
                    END,
                    CASE WHEN ST_Area(newgeom) < (($1).minareavalue)[1] -- minareavalue
                         THEN ARRAY[ST_Area(newgeom), ($2).val] 
                         ELSE ($1).minareavalue 
                    END,
                    CASE WHEN i IS NULL                                 -- combinedweightedareas
                         THEN array_append(($1).combinedweightedareas, ST_Area(newgeom)) 
                         ELSE newcombinedweightedareas 
                    END,
                    ($1).sum + ($2).val,                                -- sum
                    greatest(($1).max, ($2).val),                       -- max
                    least(($1).min, ($2).val)                           -- min
                   )::agg_areaweightedstatsstate;
        END IF;
        RETURN ret;
    END;
$$ LANGUAGE 'plpgsql';

-----------------------------------------------------------
-- _ST_AreaWeightedSummaryStats_StateFN state function variant taking a 
-- geometry and a value, converting them to a geomval
CREATE OR REPLACE FUNCTION _ST_AreaWeightedSummaryStats_StateFN(
    aws agg_areaweightedstatsstate, 
    geom geometry, 
    val double precision
)
RETURNS agg_areaweightedstatsstate AS $$
   SELECT _ST_AreaWeightedSummaryStats_StateFN($1, ($2, $3)::geomval);
$$ LANGUAGE 'sql';

-----------------------------------------------------------
-- _ST_AreaWeightedSummaryStats_StateFN state function variant defaulting 
-- the value to 1 and creating a geomval
CREATE OR REPLACE FUNCTION _ST_AreaWeightedSummaryStats_StateFN(
    aws agg_areaweightedstatsstate, 
    geom geometry
)
RETURNS agg_areaweightedstatsstate AS $$
    SELECT _ST_AreaWeightedSummaryStats_StateFN($1, ($2, 1)::geomval);
$$ LANGUAGE 'sql';

-----------------------------------------------------------
-- ST_AreaWeightedSummaryStats aggregate final function
CREATE OR REPLACE FUNCTION _ST_AreaWeightedSummaryStats_FinalFN(
    aws agg_areaweightedstatsstate
)
RETURNS agg_areaweightedstats AS $$
    DECLARE
        a RECORD;
        maxarea double precision = 0.0;
        minarea double precision = (($1).combinedweightedareas)[1];
        imax int := 1;
        imin int := 1;
        ret agg_areaweightedstats;
    BEGIN
        -- Search for the max and the min areas in the array of all distinct values
        FOR a IN SELECT n, (($1).combinedweightedareas)[n] warea 
                 FROM generate_series(1, array_length(($1).combinedweightedareas, 1)) n LOOP
            IF a.warea > maxarea THEN
                imax := a.n;
                maxarea = a.warea;
            END IF;
            IF a.warea < minarea THEN
                imin := a.n;
                minarea = a.warea;
            END IF;    
        END LOOP;

        ret := (($1).count,
                array_length(($1).distinctvalues, 1),
                ($1).unionedgeom,
                ($1).totalarea,
                ($1).totalarea / ($1).count,
                ($1).totalperimeter,
                ($1).totalperimeter / ($1).count,
                ($1).weightedsum,
                ($1).weightedsum / ($1).totalarea,
                (($1).maxareavalue)[2],
                (($1).minareavalue)[2],
                (($1).distinctvalues)[imax],
                (($1).distinctvalues)[imin],
                ($1).sum,
                ($1).sum / ($1).count, 
                ($1).max,
                ($1).min
               )::agg_areaweightedstats;
        RETURN ret;
    END;
$$ LANGUAGE 'plpgsql';

-----------------------------------------------------------
-- ST_AreaWeightedSummaryStats aggregate definition
CREATE AGGREGATE ST_AreaWeightedSummaryStats(geomval) 
(
  SFUNC=_ST_AreaWeightedSummaryStats_StateFN,
  STYPE=agg_areaweightedstatsstate,
  FINALFUNC=_ST_AreaWeightedSummaryStats_FinalFN
);

-----------------------------------------------------------
-- ST_AreaWeightedSummaryStats aggregate variant taking a 
-- geometry and a value. Useful when used with two geometry tables.
CREATE AGGREGATE ST_AreaWeightedSummaryStats(geometry, double precision) 
(
  SFUNC=_ST_AreaWeightedSummaryStats_StateFN,
  STYPE=agg_areaweightedstatsstate,
  FINALFUNC=_ST_AreaWeightedSummaryStats_FinalFN
);

-----------------------------------------------------------
-- ST_AreaWeightedSummaryStats aggregate variant defaulting 
-- the value to 1.
-- Useful when querying for stat not involving the value like
-- count, distinctcount, geom, totalarea, meanarea, totalperimeter
-- and meanperimeter.
CREATE AGGREGATE ST_AreaWeightedSummaryStats(geometry)
(
  SFUNC=_ST_AreaWeightedSummaryStats_StateFN,
  STYPE=agg_areaweightedstatsstate,
  FINALFUNC=_ST_AreaWeightedSummaryStats_FinalFN
);
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ST_SummaryStatsAgg
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
RAISE NOTICE 'min %', newstats.min;
        RETURN ret;
    END;
$$ LANGUAGE 'plpgsql';

---------------------------------------------------------------------
-- ST_SummaryStatsAgg aggregate variant state function defaulting band 
-- number to 1, exclude_nodata_value to true and sample_percent to 1.
CREATE OR REPLACE FUNCTION _ST_SummaryStatsAgg_StateFN(
    ss agg_summarystats, 
    rast raster
)
RETURNS agg_summarystats AS $$
        SELECT _ST_SummaryStatsAgg_StateFN($1, $2, 1, true, 1);
$$ LANGUAGE 'sql';

---------------------------------------------------------------------
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

---------------------------------------------------------------------
-- ST_SummaryStatsAgg aggregate definition
CREATE AGGREGATE ST_SummaryStatsAgg(raster, int, boolean, double precision)
(
  SFUNC=_ST_SummaryStatsAgg_StateFN,
  STYPE=agg_summarystats,
  FINALFUNC=_ST_SummaryStatsAgg_FinalFN
);

---------------------------------------------------------------------
-- ST_SummaryStatsAgg aggregate variant defaulting band number to 1, 
-- exclude_nodata_value to true and sample_percent to 1.
CREATE AGGREGATE ST_SummaryStatsAgg(raster)
(
  SFUNC=_ST_SummaryStatsAgg_StateFN,
  STYPE=agg_summarystats,
  FINALFUNC=_ST_SummaryStatsAgg_FinalFN
);
---------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ST_ExtractToRaster
--
--   rast raster          - Raster in which new values will be computed.
--   band integer         - Band in which new values will be computed. A variant defaulting band to 1 exist.
--   schemaname text      - Name of the schema containing the table from which to extract values.
--   tablename text       - Name of the table from which to extract values from.
--   geomcolumnname text  - Name of the column containing the geometry to use when extracting values.
--   valuecolumnname text - Name of the column containing the value to use when extracting values.
--   method text          - Name of the method of value extraction. Default to 'MEAN_OF_VALUES_AT_PIXEL_CENTROID'.
--
--   RETURNS raster
--
-- Return a raster which values are extracted from a coverage using one spatial query for each pixel. It is
-- VERY important that the coverage from which values are extracted be spatially indexed.
--
-- Methods for computing the values can be grouped in two categories: 
-- 
-- Values extracted at the pixel centroid:
--
--   - COUNT_OF_VALUES_AT_PIXEL_CENTROID: Number of features intersecting with the pixel centroid. 
--                                        Can be greater than 1 if many geometries overlaps.
--
--   - MEAN_OF_VALUES_AT_PIXEL_CENTROID: Average of all values intersecting with the pixel centroid. 
--                                       Can be greater than 1 if many geometries overlaps.
--
-- Values extracted for the whole square pixel:
--
--   - COUNT_OF_POLYGONS: Number of polygons or multipolygons intersecting with the pixel.
--
--   - COUNT_OF_LINESTRINGS: Number of linestrings or multilinestrings intersecting with the pixel.
--
--   - COUNT_OF_POINTS: Number of points or multipoints intersecting with the pixel.
--
--   - COUNT_OF_GEOMETRIES: Number of geometries (whatever they are) intersecting with the pixel.
--
--   - VALUE_OF_BIGGEST: Value associated with the polygon covering the biggest area in the pixel.
--
--   - VALUE_OF_MERGED_BIGGEST: Value associated with the polygon covering the biggest area in the  
--                              pixel. Same value polygons are merged first.
--
--   - VALUE_OF_MERGED_SMALLEST: Value associated with the polygon covering the smallest area in the  
--                               pixel. Same value polygons are merged first.
--
--   - MIN_AREA: Area of the geometry occupying the smallest area in the pixel.
--
--   - SUM_OF_AREAS: Sum of the areas of all polygons intersecting with the pixel.
--
--   - PROPORTION_OF_COVERED_AREA: Proportion, between 0.0 and 1.0, of the pixel area covered by the 
--                                 conjunction of all the polygons intersecting with the pixel.
--
--   - AREA_WEIGHTED_MEAN_OF_VALUES: Mean of all polygon values weighted by their relative areas.
--
-- Many more methods can be added over time. An almost exhaustive list of possible method can be find
-- at objective FV.27 in this page: http://trac.osgeo.org/postgis/wiki/WKTRaster/SpecificationWorking03
--
-- Self contained and typical example:
--
-- We first create a table of geometries:
-- 
-- DROP TABLE IF EXISTS st_extracttoraster_example;
-- CREATE TABLE st_extracttoraster_example AS
-- SELECT 'a'::text id, 1 val, ST_GeomFromText('POLYGON((0 1, 10 2, 10 0, 0 1))') geom
-- UNION ALL
-- SELECT 'b'::text, 2, ST_GeomFromText('POLYGON((10 1, 0 2, 0 0, 10 1))')
-- UNION ALL
-- SELECT 'c'::text, 1, ST_GeomFromText('POLYGON((1 0, 1 2, 4 2, 4 0, 1 0))')
-- UNION ALL
-- SELECT 'd'::text, 4, ST_GeomFromText('POLYGON((7 0, 7 2, 8 2, 8 0, 7 0))')
-- UNION ALL
-- SELECT 'e'::text, 5, ST_GeomFromText('LINESTRING(0 0, 10 2)')
-- UNION ALL
-- SELECT 'f'::text, 6, ST_GeomFromText('LINESTRING(4 0, 6 2)')
-- UNION ALL
-- SELECT 'g'::text, 7, ST_GeomFromText('POINT(4 1.5)')
-- UNION ALL
-- SELECT 'h'::text, 8, ST_GeomFromText('POINT(8 0.5)')
-- UNION ALL
-- SELECT 'i'::text, 9, ST_GeomFromText('MULTIPOINT(6 0.5, 7 0.6)')
--
-- We then extract the values to a raster:
--
-- SELECT ST_ExtractToRaster(rast, 'public', 'test_extracttoraster', 'geom', 'val', 'AREA_WEIGHTED_MEAN_OF_VALUES') rast
-- FROM ST_AddBand(ST_MakeEmptyRaster(2, 2, 0.0, 2.0, 5.0, -1.0, 0, 0, 0), '32BF') rast
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 11/10/2013 v. 1.10
-----------------------------------------------------------
CREATE OR REPLACE FUNCTION ST_CentroidValue4ma(
    pixel float, 
    pos int[], 
    VARIADIC args text[]
)
RETURNS FLOAT AS $$ 
    DECLARE
        pixelgeom text;
        result float4;
        query text;
    BEGIN
        -- args[1] = raster width
        -- args[2] = raster height
        -- args[3] = raster upperleft x
        -- args[4] = raster upperleft y
        -- args[5] = raster scale x
        -- args[6] = raster scale y
        -- args[7] = raster skew x
        -- args[8] = raster skew y
        -- args[9] = raster SRID
        -- args[10] = geometry table schema name
        -- args[11] = geometry table name
        -- args[12] = geometry table geometry column name
        -- args[13] = geometry table value column name
        -- args[14] = method
        
        -- Reconstruct the pixel centroid
        pixelgeom = ST_AsText(
                      ST_Centroid(
                        ST_PixelAsPolygon(
                          ST_MakeEmptyRaster(args[1]::integer,  -- raster width
                                             args[2]::integer,  -- raster height
                                             args[3]::float,    -- raster upperleft x
                                             args[4]::float,    -- raster upperleft y
                                             args[5]::float,    -- raster scale x
                                             args[6]::float,    -- raster scale y
                                             args[7]::float,    -- raster skew x
                                             args[8]::float,    -- raster skew y
                                             args[9]::integer   -- raster SRID
                                            ),
                                          pos[1]::integer, -- x coordinate of the current pixel
                                          pos[2]::integer  -- y coordinate of the current pixel
                                         )));

        -- Query the appropriate value
        IF args[14] = 'COUNT_OF_VALUES_AT_PIXEL_CENTROID' THEN
            query = 'SELECT count(' || quote_ident(args[13]) || 
                    ') FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || quote_ident(args[12]) || ')';
        ELSEIF args[14] = 'MEAN_OF_VALUES_AT_PIXEL_CENTROID' THEN
            query = 'SELECT avg(' || quote_ident(args[13]) || 
                    ') FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || quote_ident(args[12]) || ')';
        ELSE
            query = 'SELECT NULL';
        END IF;
--RAISE NOTICE 'query = %', query;
        EXECUTE query INTO result;
        RETURN result;
    END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

-- To be defined
CREATE OR REPLACE FUNCTION ST_GeomValue4ma(
    pixel float, 
    pos int[], 
    VARIADIC args text[]
)
RETURNS FLOAT AS $$ 
    DECLARE
        pixelgeom text;
        result float4;
        query text;
    BEGIN
        -- args[1] = raster width
        -- args[2] = raster height
        -- args[3] = raster upperleft x
        -- args[4] = raster upperleft y
        -- args[5] = raster scale x
        -- args[6] = raster scale y
        -- args[7] = raster skew x
        -- args[8] = raster skew y
        -- args[9] = raster SRID
        -- args[10] = geometry table schema name
        -- args[11] = geometry table name
        -- args[12] = geometry table geometry column name
        -- args[13] = geometry table value column name
        -- args[14] = method

--RAISE NOTICE 'x = %, y = %', pos[1], pos[2];        
        -- Reconstruct the pixel square
	pixelgeom = ST_AsText(
	              ST_PixelAsPolygon(
	                ST_MakeEmptyRaster(args[1]::integer, -- raster width
	                                   args[2]::integer, -- raster height
	                                   args[3]::float,   -- raster upperleft x
	                                   args[4]::float,   -- raster upperleft y
	                                   args[5]::float,   -- raster scale x
	                                   args[6]::float,   -- raster scale y
	                                   args[7]::float,   -- raster skew x
	                                   args[8]::float,   -- raster skew y
	                                   args[9]::integer  -- raster SRID
	                                  ), 
	                                pos[1]::integer, -- x coordinate of the current pixel
	                                pos[2]::integer  -- y coordinate of the current pixel
	                               ));
        -- Query the appropriate value
        IF args[14] = 'COUNT_OF_POLYGONS' THEN -- Number of polygons intersecting the pixel
            query = 'SELECT count(' || quote_ident(args[13]) || 
                    ') FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE (ST_GeometryType(' || quote_ident(args[12]) || ') = ''ST_Polygon'' OR 
                             ST_GeometryType(' || quote_ident(args[12]) || ') = ''ST_MultiPolygon'') AND 
                            ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || quote_ident(args[12]) || ') AND 
                            ST_Area(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || 
                            quote_ident(args[12]) || ')) > 0.0000000001';
                    
        ELSEIF args[14] = 'COUNT_OF_LINESTRINGS' THEN -- Number of linestring intersecting the pixel
            query = 'SELECT count(' || quote_ident(args[13]) || 
                    ') FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE (ST_GeometryType(' || quote_ident(args[12]) || ') = ''ST_LineString'' OR 
                             ST_GeometryType(' || quote_ident(args[12]) || ') = ''ST_MultiLineString'') AND
                             ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || quote_ident(args[12]) || ') AND 
                             ST_Length(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || 
                             quote_ident(args[12]) || ')) > 0.0000000001';
                    
        ELSEIF args[14] = 'COUNT_OF_POINTS' THEN -- Number of points intersecting the pixel
            query = 'SELECT count(' || quote_ident(args[13]) || 
                    ') FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE (ST_GeometryType(' || quote_ident(args[12]) || ') = ''ST_Point'' OR 
                             ST_GeometryType(' || quote_ident(args[12]) || ') = ''ST_MultiPoint'') AND
                             ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || quote_ident(args[12]) || ')';
                    
        ELSEIF args[14] = 'COUNT_OF_GEOMETRIES' THEN -- Number of geometries intersecting the pixel
            query = 'SELECT count(' || quote_ident(args[13]) || 
                    ') FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || quote_ident(args[12]) || ')';
                    
        ELSEIF args[14] = 'VALUE_OF_BIGGEST' THEN -- Value of the geometry occupying the biggest area in the pixel
            query = 'SELECT ' || quote_ident(args[13]) || 
                    ' val FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || quote_ident(args[12]) || 
                    ') ORDER BY ST_Area(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), 
                                                        ' || quote_ident(args[12]) || 
                    ')) DESC, val DESC LIMIT 1';

        ELSEIF args[14] = 'VALUE_OF_MERGED_BIGGEST' THEN -- Value of the combined geometry occupying the biggest area in the pixel
            query = 'SELECT val FROM (SELECT ' || quote_ident(args[13]) || ' val, 
                                            sum(ST_Area(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                                                                        || quote_ident(args[12]) ||
                    '))) sumarea FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || quote_ident(args[12]) || 
                    ') GROUP BY val) foo ORDER BY sumarea DESC, val DESC LIMIT 1';

        ELSEIF args[14] = 'MIN_AREA' THEN -- Area of the geometry occupying the smallest area in the pixel
            query = 'SELECT area FROM (SELECT ST_Area(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), 
                                                                      ' || quote_ident(args[12]) || 
                    ')) area FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || quote_ident(args[12]) || 
                    ')) foo WHERE area > 0.0000000001 ORDER BY area LIMIT 1';

        ELSEIF args[14] = 'VALUE_OF_MERGED_SMALLEST' THEN -- Value of the combined geometry occupying the biggest area in the pixel
            query = 'SELECT val FROM (SELECT ' || quote_ident(args[13]) || ' val, 
                                             sum(ST_Area(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                                                                                           || quote_ident(args[12]) ||
                    '))) sumarea FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || quote_ident(args[12]) || 
                    ') AND ST_Area(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                                                                     || quote_ident(args[12]) || ')) > 0.0000000001 
                      GROUP BY val) foo ORDER BY sumarea ASC, val DESC LIMIT 1';

        ELSEIF args[14] = 'SUM_OF_AREAS' THEN -- Sum of areas intersecting with the pixel (no matter the value)
            query = 'SELECT sum(ST_Area(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                                                                          || quote_ident(args[12]) ||
                    '))) sumarea FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || quote_ident(args[12]) || 
                    ')';

        ELSEIF args[14] = 'PROPORTION_OF_COVERED_AREA' THEN -- Proportion of the pixel covered by polygons (no matter the value)
            query = 'SELECT ST_Area(ST_Union(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                                                                               || quote_ident(args[12]) ||
                    ')))/ST_Area(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || ')) sumarea 
                     FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || quote_ident(args[12]) || 
                    ')';

        ELSEIF args[14] = 'AREA_WEIGHTED_MEAN_OF_VALUES' THEN -- Mean of every geometry weighted by their area
            query = 'SELECT CASE WHEN sum(area) = 0 THEN 0 ELSE sum(area * val) / sum(area) END 
                     FROM (SELECT ' || quote_ident(args[13]) || ' val, 
                                 ST_Area(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                                                         || quote_ident(args[12]) || ')) area 
                           FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                         ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || quote_ident(args[12]) || 
                    ')) foo';
        ELSE
            query = 'SELECT NULL';
        END IF;
--RAISE NOTICE 'query = %', query;
        EXECUTE query INTO result;
        RETURN result;
    END; 
$$ LANGUAGE 'plpgsql' IMMUTABLE;

-- To be defined
CREATE OR REPLACE FUNCTION ST_ExtractToRaster(
    rast raster, 
    band integer, 
    schemaname name, 
    tablename name, 
    geomcolumnname name, 
    valuecolumnname name, 
    method text DEFAULT 'MEAN_OF_VALUES_AT_PIXEL_CENTROID'
)
RETURNS raster AS $$ 
    DECLARE
        query text;
        newrast raster;
        fct2call text;
    BEGIN
        -- Reconstruct the pixel shape or centroid
        IF right(method, 5) = 'TROID' THEN
            fct2call = 'ST_CentroidValue4ma';
        ELSE
            fct2call = 'ST_GeomValue4ma';
        END IF;

        query = 'SELECT ST_MapAlgebraFct($1, $2, ''' || fct2call || '(float, integer[], text[])''::regprocedure, 
					 ST_Width($1)::text,
					 ST_Height($1)::text,
					 ST_UpperLeftX($1)::text,
					 ST_UpperLeftY($1)::text,
					 ST_ScaleX($1)::text,
					 ST_ScaleY($1)::text,
					 ST_SkewX($1)::text,
					 ST_SkewY($1)::text,
					 ST_SRID($1)::text,' || 
					 quote_literal(schemaname) || ', ' ||
					 quote_literal(tablename) || ', ' ||
					 quote_literal(geomcolumnname) || ', ' ||
					 quote_literal(valuecolumnname) || ', ' ||
					 quote_literal(upper(method)) || '
					) rast';
        EXECUTE query INTO newrast USING rast, band;
        RETURN ST_AddBand(ST_DeleteBand(rast, band), newrast, 1, band);
    END
$$ LANGUAGE 'plpgsql' IMMUTABLE;

---------------------------------------------------------------------
-- ST_ExtractToRaster variant defaulting band number to 1
CREATE OR REPLACE FUNCTION ST_ExtractToRaster(
    rast raster, 
    schemaname name, 
    tablename name, 
    geomcolumnname name, 
    valuecolumnname name, 
    method text DEFAULT 'MEAN_OF_VALUES_AT_PIXEL_CENTROID'
)
RETURNS raster AS $$
    SELECT ST_ExtractToRaster($1, 1, $2, $3, $4, $5, $6)
$$ LANGUAGE 'sql';
---------------------------------------------------------------------
