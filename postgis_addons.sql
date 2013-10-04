-------------------------------------------------------------------------------
-- PostGIS PL/pgSQL Add-ons - Main installation file
-- Version 1.8 for PostGIS 2.1.x and PostgreSQL 9.x
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
--   ST_CreateIndexRaster - Creates a new raster as an index grid.
--   ST_RandomPoints - Generates points located randomly inside a geometry.
--   ST_ColumnExists - Return true if a column exist in a table.
--   ST_AddUniqueID - Add a column to a table and fill it with a unique integer starting at 1.
--
-------------------------------------------------------------------------------
-- Begin Function Definitions...
-------------------------------------------------------------------------------
-- ST_DeleteBand
--
--   rast raster - Raster in which to remove a band.
--   band int    - Number of the band to remove.
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
--   geom - Geometry in which to create the random points. Should be a polygon 
--          or a multipolygon.
--   nb   - Number of random points to create.
--   seed - Value between -1.0 and 1.0, inclusive, setting the seek if repeatable 
--          results are desired. Default to null.
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
$$ LANGUAGE 'plpgsql' VOLATILE STRICT;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ST_ColumnExists
--
--   schemaname - Name of the schema containing the table in which to check for 
--                the existance of a column.
--   tablename  - Name of the table in which to check for the existance of a column.
--   columnname - Name of the column to check for the existence of.
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
-- Variant defaulting to the 'public' schemaname
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
--   schemaname    - Name of the schema containing the table in which to check for 
--                   the existance of a column.
--   tablename     - Name of the table in which to check for the existance of a column.
--   columnname    - Name of the column to check for the existence of.
--   replacecolumn - If set to true, drop and replace the column if it already exists.
--
-- Add a column to a table and fill it with a unique integer starting at 1.
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
-- Variant defaulting to the 'public' schemaname
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
--   geomval - The geomval couple resulting from ST_Intersection(raster, geometry).
--             A variant taking a geometry and a value also exist.
--
-- Aggregate computing statistics of a series of intersecting value weighted by the 
-- area of the corresponding geometry.
--
-- Statictics computed are:
--
--   - count          - Number of values in the aggregate.
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
--       FROM (SELECT ST_GeomFromEWKT('SRID=4269;POLYGON((0 0,0 10, 10 10, 10 0, 0 0))') as geom, 'a' as id, 100 as val
--             UNION ALL
--             SELECT ST_GeomFromEWKT('SRID=4269;POLYGON((12 0,12 1, 13 1, 13 0, 12 0))') as geom, 'a' as id, 1 as val
--             UNION ALL
--             SELECT ST_GeomFromEWKT('SRID=4269;POLYGON((10 0, 10 2, 12 2, 12 0, 10 0))') as geom, 'b' as id, 4 as val
--             UNION ALL
--             SELECT ST_GeomFromEWKT('SRID=4269;POLYGON((10 2, 10 3, 12 3, 12 2, 10 2))') as geom, 'b' as id, 2 as val
--             UNION ALL
--             SELECT ST_GeomFromEWKT('SRID=4269;POLYGON((10 3, 10 4, 12 4, 12 3, 10 3))') as geom, 'b' as id, 2 as val
--             UNION ALL
--             SELECT ST_GeomFromEWKT('SRID=4269;POLYGON((10 4, 10 5, 12 5, 12 4, 10 4))') as geom, 'b' as id, 2 as val
--            ) foo1
--       GROUP BY id
--      ) foo2
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
--      ) foo2
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 10/02/2013 v. 1.8
-----------------------------------------------------------
-- Type returned by the final state function
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
-- Type returned by the state function
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
-- State function
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
            ret := (($1).count + 1, -- count
                    CASE WHEN i IS NULL 
                         THEN array_append(($1).distinctvalues, ($2).val) -- distinctvalues
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
-- State function variant taking a geometry and a value, converting them to a geomval
CREATE OR REPLACE FUNCTION _ST_AreaWeightedSummaryStats_StateFN(
    aws agg_areaweightedstatsstate, 
    geom geometry, 
    val double precision
)
RETURNS agg_areaweightedstatsstate AS $$
   SELECT _ST_AreaWeightedSummaryStats_StateFN($1, ($2, $3)::geomval);
$$ LANGUAGE 'sql';
-----------------------------------------------------------
-- State function variant defaulting the value to 1 and creating a geomval
CREATE OR REPLACE FUNCTION _ST_AreaWeightedSummaryStats_StateFN(
    aws agg_areaweightedstatsstate, 
    geom geometry
)
RETURNS agg_areaweightedstatsstate AS $$
    SELECT _ST_AreaWeightedSummaryStats_StateFN($1, ($2, 1)::geomval);
$$ LANGUAGE 'sql';
-----------------------------------------------------------
-- Final function
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
-- Aggregate definition
CREATE AGGREGATE ST_AreaWeightedSummaryStats(
    geomval
) 
(
  SFUNC=_ST_AreaWeightedSummaryStats_StateFN,
  STYPE=agg_areaweightedstatsstate,
  FINALFUNC=_ST_AreaWeightedSummaryStats_FinalFN
);
-----------------------------------------------------------
-- Aggregate variant taking a geometry and a value
CREATE AGGREGATE ST_AreaWeightedSummaryStats(
    geometry, 
    double precision
) 
(
  SFUNC=_ST_AreaWeightedSummaryStats_StateFN,
  STYPE=agg_areaweightedstatsstate,
  FINALFUNC=_ST_AreaWeightedSummaryStats_FinalFN
);
-----------------------------------------------------------
-- Aggregate variant defaulting the value to 1
CREATE AGGREGATE ST_AreaWeightedSummaryStats(
    geometry
)
(
  SFUNC=_ST_AreaWeightedSummaryStats_StateFN,
  STYPE=agg_areaweightedstatsstate,
  FINALFUNC=_ST_AreaWeightedSummaryStats_FinalFN
);
-------------------------------------------------------------------------------
