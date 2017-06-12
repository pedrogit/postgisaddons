-------------------------------------------------------------------------------
-- PostGIS PL/pgSQL Add-ons - Main installation file
-- Version 1.26 for PostGIS 2.1.x and PostgreSQL 9.x
-- http://github.com/pedrogit/postgisaddons
--
-- This is free software; you can redistribute and/or modify it under
-- the terms of the GNU General Public Licence. See the COPYING file.
--
-- Copyright (C) 2013-2017 Pierre Racine <pierre.racine@sbf.ulaval.ca>.
-- 
-------------------------------------------------------------------------------
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
-- unsinstall file. All functions are documented inside the main function file 
-- (this file). 
--
-- To be included, a function:
--
--   - must be written in pure PL/pgSQL or SQL code (no C or any compilable code),
--   - must be generic enough to be useful to other PostGIS users,
--   - must follow functions and variables naming and indentation conventions 
--     already in use in the files,
--   - must be documented according to the rules defined below in this file,
--   - must be accompagned by a series of test in the postgis_addons_test.sql file,
--   - must be accompagned by the appropriate DROP statements in the 
--     expostgis_addons_uninstall.sql file.
--
-- You must also accept to release your work under the same licence already in use for this product.
-- 
-------------------------------------------------------------------------------
--
-- File description
-- 
--   - postgis_addons.sql             Main redistributable file containing all the 
--                                    functions.
--   - postgis_addons_uninstall.sql   Uninstallation file.
--   - postgis_addons_test.sql        Self contained test file to be executed after  
--                                    installation and before any commit of the main 
--                                    file.
-- 
-------------------------------------------------------------------------------
--
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
-- A short description of each new function should also be provided at the beginning
-- of the file (in the section below).
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
--   ST_ColumnExists - Returns true if a column exist in a table.
--
--   ST_HasBasicIndex - Returns true if a table column has at least one index defined.
--
--   ST_AddUniqueID - Adds a column to a table and fill it with a unique integer 
--                    starting at 1.
--
--   ST_AreaWeightedSummaryStats - Aggregate function computing statistics on a 
--                                 series of intersected values weighted by the 
--                                 area of the corresponding geometry.
--
--   ST_ExtractToRaster - Compute a raster band by extracting values for the centroid 
--                        or the footprint of each pixel from a global geometry
--                        coverage using different methods like count, min, max, 
--                        mean, value of biggest geometry or area weighted mean 
--                        of values.
--
--   ST_GlobalRasterUnion - Build a new raster by extracting all the pixel values
--                          from a global raster coverage using different methods
--                          like count, min, max, mean, stddev and range. Similar
--                          and slower but more flexible than ST_Union.
--
--   ST_BufferedUnion - Alternative to ST_Union making a buffer around each geometry 
--                      before unioning and removing it afterward. Used when ST_Union 
--                      leaves internal undesirable vertexes after a complex union 
--                      or when wanting to remove holes from the resulting union.
--
--   ST_NBiggestExteriorRings - Returns the n biggest exterior rings of the provided 
--                              geometry based on their area or thir number of vertex.
--
--   ST_BufferedSmooth - Returns a smoothed version of the geometry. The smoothing is 
--                       done by making a buffer around the geometry and removing it 
--                       afterward.
--
--   ST_DifferenceAgg - Returns the first geometry after having removed all the 
--                      subsequent geometries in the aggregate. Used to remove 
--                      overlaps in a geometry table.
--
--   ST_TrimMulti - Returns a multigeometry from which simple geometries having an area  
--                  smaller than the tolerance parameter have been removed.
--
--   ST_SplitAgg - Returns the first geometry as a set of geometries after being split 
--                 by all the second geometries being part of the aggregate.
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
        bandarray int[];
    BEGIN
        IF rast IS NULL THEN
            RETURN null;
        END IF;
        IF band IS NULL OR band < 1 OR band > numband THEN
            RETURN rast;
        END IF;
        IF band = 1 AND numband = 1 THEN
            RETURN ST_MakeEmptyRaster(rast);
        END IF;

        -- Construct the array of band to extract skipping the band to delete
        SELECT array_agg(i) INTO bandarray
        FROM generate_series(1, numband) i
        WHERE i != band;

        RETURN ST_Band(rast, bandarray);
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
-- Mathieu Basille <basille.web@ase-research.org>
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
-- Returns true if a column exist in a table. Mainly defined to be used by ST_AddUniqueID().
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
-- ST_HasBasicIndex
--
--   schemaname name - Name of the schema containing the table for which to check for 
--                     the existance of an index.
--   tablename name  - Name of the table for which to check for the existance of an index.
--   columnname name - Name of the column to check for the existence of an index.
--
--   RETURNS boolean
--
-- Returns true if a table column has at least one index defined
-----------------------------------------------------------
-- Self contained example:
--
-- SELECT ST_HasBasicIndex('public', 'spatial_ref_sys', 'srid') ;
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 08/06/2017 v. 1.25
-----------------------------------------------------------
CREATE OR REPLACE FUNCTION ST_HasBasicIndex(
    schemaname name, 
    tablename name,
    columnname name
)
RETURNS boolean AS $$
    DECLARE
        query text;
        coltype text;
        hasindex boolean := FALSE;
    BEGIN
        -- Determine the type of the column
        query := 'SELECT typname 
                 FROM pg_namespace
		 LEFT JOIN pg_class ON (pg_namespace.oid = pg_class.relnamespace)
		 LEFT JOIN pg_attribute ON (pg_attribute.attrelid = pg_class.oid)
		 LEFT JOIN pg_type ON (pg_type.oid = pg_attribute.atttypid)
		 WHERE nspname = ''' || schemaname || ''' AND relname = ''' || tablename || ''' AND attname = ''' || columnname || ''';';
        EXECUTE QUERY query INTO coltype;
        IF coltype IS NULL THEN
            --RAISE EXCEPTION 'column not found';
            RETURN NULL;
        ELSIF coltype = 'raster' THEN
            -- When column type is RASTER we ignore the column name and 
            -- only check if the type of the index is gist since it is a functional 
            -- index and we can not check on which column it is applied
            query := 'SELECT TRUE
                      FROM pg_index
                      LEFT OUTER JOIN pg_class relclass ON (relclass.oid = pg_index.indrelid)
                      LEFT OUTER JOIN pg_namespace ON (pg_namespace.oid = relclass.relnamespace)
                      LEFT OUTER JOIN pg_class idxclass ON (idxclass.oid = pg_index.indexrelid)
                      LEFT OUTER JOIN pg_am ON (pg_am.oid = idxclass.relam)
                      WHERE relclass.relkind = ''r'' AND amname = ''gist'' 
                      AND nspname = ''' || schemaname || ''' AND relclass.relname = ''' || tablename || ''';';
            EXECUTE QUERY query INTO hasindex;
        ELSE
           -- Otherwise we check for an index on the right column
           query := 'SELECT TRUE 
                     FROM pg_index
                     LEFT OUTER JOIN pg_class relclass ON (relclass.oid = pg_index.indrelid) 
                     LEFT OUTER JOIN pg_namespace ON (pg_namespace.oid = relclass.relnamespace) 
                     LEFT OUTER JOIN pg_class idxclass ON (idxclass.oid = pg_index.indexrelid) 
                     --LEFT OUTER JOIN pg_am ON (pg_am.oid = idxclass.relam) 
                     LEFT OUTER JOIN pg_attribute ON (pg_attribute.attrelid = relclass.oid AND indkey[0] = attnum) 
                     WHERE relclass.relkind = ''r'' AND indkey[0] != 0 
                     AND nspname = ''' || schemaname || ''' AND relclass.relname = ''' || tablename || ''' AND attname = ''' || columnname || ''';';
           EXECUTE QUERY query INTO hasindex;
        END IF;
        IF hasindex IS NULL THEN
	    hasindex = FALSE;
        END IF;
        RETURN hasindex; 
    END; 
$$ LANGUAGE 'plpgsql' VOLATILE STRICT;
-----------------------------------------------------------

-------------------------------------------------------------------------------
-- ST_AddUniqueID
--
--   schemaname name       - Name of the schema containing the table in which to check for 
--                           the existance of a column.
--   tablename name        - Name of the table in which to check for the existance of a column.
--   columnname name       - Name of the new id column to check for the existence of.
--   replacecolumn boolean - If set to true, drop and replace the new id column if it already exists. Default to false.
--   indexit boolean       - If set to true, create an index on the new id column. Default to true.
--
--   RETURNS boolean
--
-- Adds a column to a table and fill it with a unique integer starting at 1. Returns
-- true if the operation succeeded, false otherwise.
-- This is useful when you don't want to create a new table for whatever reason.
-- If you want to create a new table instead of using this function just:
--
-- CREATE SEQUENCE foo_id_seq;
-- CREATE TABLE newtable AS
-- SELECT *, nextval('foo_id_seq') id
-- FROM oldtable;
-----------------------------------------------------------
-- Self contained example:
--
-- SELECT ST_AddUniqueID('spatial_ref_sys', 'id', true, true);
-- ALTER TABLE spatial_ref_sys DROP COLUMN id;
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 10/02/2013 v. 1.7
-----------------------------------------------------------

-----------------------------------------------------------
CREATE OR REPLACE FUNCTION ST_AddUniqueID(
    schemaname name, 
    tablename name, 
    columnname name, 
    replacecolumn boolean DEFAULT false,
    indexit boolean DEFAULT true
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

        IF indexit THEN
            EXECUTE 'CREATE INDEX ' || tablename || '_' || columnname || '_idx ON ' || fqtn || ' USING btree(' || columnname || ');';
        END IF;

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
-- ST_ExtractToRaster
--
--   rast raster             - Raster in which new values will be computed.
--   band integer            - Band in which new values will be computed. A variant defaulting band to 1 exist.
--   schemaname text         - Name of the schema containing the table from which to extract values.
--   tablename text          - Name of the table from which to extract values from.
--   geomrastcolumnname text - Name of the column containing the geometry or the raster to use when extracting values.
--   valuecolumnname text    - Name of the column containing the value to use when extracting values. Should be null
--                             when extracting from a raster coverage and can be null for certain methods not implying
--                             geometries values.
--   method text             - Name of the method of value extraction. Default to 'MEAN_OF_VALUES_AT_PIXEL_CENTROID'.
--
--   RETURNS raster
--
-- Return a raster which values are extracted from a coverage using one spatial query for each pixel. It is
-- VERY important that the coverage from which values are extracted is spatially indexed.
--
-- Methods for computing the values can be grouped in two categories: 
-- 
-- Values extracted at the pixel centroid:
--
--   - COUNT_OF_VALUES_AT_PIXEL_CENTROID: Number of features intersecting with the pixel centroid. 
--                                        Greater than 1 when many geometries overlaps.
--
--   - MEAN_OF_VALUES_AT_PIXEL_CENTROID: Average of all values intersecting with the pixel centroid. 
--                                       Many values are taken into account when many geometries overlaps.
--
--   - COUNT_OF_RASTER_VALUES_AT_PIXEL_CENTROID, 
--     FIRST_RASTER_VALUE_AT_PIXEL_CENTROID, 
--     MIN_OF_RASTER_VALUES_AT_PIXEL_CENTROID, 
--     MAX_OF_RASTER_VALUES_AT_PIXEL_CENTROID,
--     SUM_OF_RASTER_VALUES_AT_PIXEL_CENTROID, 
--     MEAN_OF_RASTER_VALUES_AT_PIXEL_CENTROID,
--     STDDEVP_OF_RASTER_VALUES_AT_PIXEL_CENTROID and 
--     RANGE_OF_RASTER_VALUES_AT_PIXEL_CENTROID 
--     are for the ST_GlobalRasterUnion() function. When those methods are used,
--     geomrastcolumnname should be a column of type raster and valuecolumnname should be null.
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
--   - MIN_AREA: Area of the geometry covering the smallest area in the pixel.
--
--   - SUM_OF_AREAS: Sum of the areas of all polygons intersecting with the pixel.
--
--   - SUM_OF_LENGTHS: Sum of the lengths of all linestrings intersecting with the pixel.
--
--   - PROPORTION_OF_COVERED_AREA: Proportion, between 0.0 and 1.0, of the pixel area covered by the 
--                                 conjunction of all the polygons intersecting with the pixel.
--
--   - AREA_WEIGHTED_MEAN_OF_VALUES: Mean of all polygon values weighted by the proportion of the area
--                                   of the target polygon they cover.
--                                   The weighted sum is divided by the maximum between the 
--                                   area of the geometry and the sum of all the weighted geometry 
--                                   areas. i.e. If the geometry being processed is not entirely 
--                                   covered by other geometries, the value is multiplied by the 
--                                   proportion of the covering area.
--
--   - AREA_WEIGHTED_MEAN_OF_VALUES_2: Mean of all polygon values weighted by the proportion of the area
--                                     of the target polygon they cover.
--                                     The weighted sum is divided by the sum of all the weighted 
--                                     geometry areas. i.e. Even if a geometry is not entirely covered 
--                                     by other geometries, it gets the full weighted value.
--
--   - AREA_WEIGHTED_SUM_OF_RASTER_VALUES, 
--     SUM_OF_AREA_PROPORTIONAL_RASTER_VALUES, 
--     AREA_WEIGHTED_MEAN_OF_RASTER_VALUES and 
--     AREA_WEIGHTED_MEAN_OF_RASTER_VALUES_2 
--     are for the ST_GlobalRasterUnion() function. When those methods are used, 
--     geomrastcolumnname should be a column of type raster and valuecolumnname should be null.
--
-- Many more methods can be added over time. An almost exhaustive list of possible method can be find
-- at objective FV.27 in this page: http://trac.osgeo.org/postgis/wiki/WKTRaster/SpecificationWorking03
--
-- Self contained example:
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
--
--
-- Typical example
--
-- In the typical case the geometry table already exists and you already have 
-- a raster table that serve as a reference grid. You have to pass to 
-- ST_ExtractToRaster() an empty raster created from the reference grid to which 
-- you add a band having the proper pixel type for storing the desired value.
--
-- SELECT ST_ExtractToRaster(
--          ST_AddBand(
--            ST_MakeEmptyRaster(rast), '32BF'), 'public', 'geomtable', 'geom', 'val', 'AREA_WEIGHTED_MEAN_OF_VALUES') rast
-- FROM refrastertable;
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 11/10/2013 v. 1.10
-----------------------------------------------------------
-- Callback function computing a value for the pixel centroid
CREATE OR REPLACE FUNCTION ST_ExtractPixelCentroidValue4ma(
    pixel double precision[][][], 
    pos int[][], 
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
        -- args[10] = geometry or raster table schema name
        -- args[11] = geometry or raster table name
        -- args[12] = geometry or raster table geometry or raster column name
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
                                          pos[0][1]::integer, -- x coordinate of the current pixel
                                          pos[0][2]::integer  -- y coordinate of the current pixel
                                         )));

        -- Query the appropriate value
        IF args[14] = 'COUNT_OF_VALUES_AT_PIXEL_CENTROID' THEN
            query = 'SELECT count(' || quote_ident(args[13]) || 
                    ') FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || 
                    quote_ident(args[12]) || ')';
                    
        ELSEIF args[14] = 'MEAN_OF_VALUES_AT_PIXEL_CENTROID' THEN
            query = 'SELECT avg(' || quote_ident(args[13]) || 
                    ') FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || 
                    quote_ident(args[12]) || ')';
        ----------------------------------------------------------------
        -- Methods for the ST_GlobalRasterUnion() function
        ---------------------------------------------------------------- 
        ELSEIF args[14] = 'COUNT_OF_RASTER_VALUES_AT_PIXEL_CENTROID' THEN
            query = 'SELECT count(ST_Value(' || quote_ident(args[12]) || ', ST_GeomFromText(' || quote_literal(pixelgeom) || 
                    ', ' || args[9] || '))) 
                    FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' ||
                    quote_ident(args[12]) || ')';
                    
        ELSEIF args[14] = 'FIRST_RASTER_VALUE_AT_PIXEL_CENTROID' THEN
            query = 'SELECT ST_Value(' || quote_ident(args[12]) || ', ST_GeomFromText(' || quote_literal(pixelgeom) || 
                    ', ' || args[9] || ')) 
                    FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' ||
                    quote_ident(args[12]) || ') LIMIT 1';
                    
        ELSEIF args[14] = 'MIN_OF_RASTER_VALUES_AT_PIXEL_CENTROID' THEN
            query = 'SELECT min(ST_Value(' || quote_ident(args[12]) || ', ST_GeomFromText(' || quote_literal(pixelgeom) || 
                    ', ' || args[9] || '))) 
                    FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' ||
                    quote_ident(args[12]) || ')';

        ELSEIF args[14] = 'MAX_OF_RASTER_VALUES_AT_PIXEL_CENTROID' THEN
            query = 'SELECT max(ST_Value(' || quote_ident(args[12]) || ', ST_GeomFromText(' || quote_literal(pixelgeom) || 
                    ', ' || args[9] || '))) 
                    FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' ||
                    quote_ident(args[12]) || ')';

        ELSEIF args[14] = 'SUM_OF_RASTER_VALUES_AT_PIXEL_CENTROID' THEN
            query = 'SELECT sum(ST_Value(' || quote_ident(args[12]) || ', ST_GeomFromText(' || quote_literal(pixelgeom) || 
                    ', ' || args[9] || '))) 
                    FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' ||
                    quote_ident(args[12]) || ')';

        ELSEIF args[14] = 'MEAN_OF_RASTER_VALUES_AT_PIXEL_CENTROID' THEN
            query = 'SELECT avg(ST_Value(' || quote_ident(args[12]) || ', ST_GeomFromText(' || quote_literal(pixelgeom) || 
                    ', ' || args[9] || '))) 
                    FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' ||
                    quote_ident(args[12]) || ')';

        ELSEIF args[14] = 'STDDEVP_OF_RASTER_VALUES_AT_PIXEL_CENTROID' THEN
            query = 'SELECT stddev_pop(ST_Value(' || quote_ident(args[12]) || ', ST_GeomFromText(' || quote_literal(pixelgeom) || 
                    ', ' || args[9] || '))) 
                    FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' ||
                    quote_ident(args[12]) || ')';

        ELSEIF args[14] = 'RANGE_OF_RASTER_VALUES_AT_PIXEL_CENTROID' THEN
            query = 'SELECT max(val) - min(val)
                     FROM (SELECT ST_Value(' || quote_ident(args[12]) || ', ST_GeomFromText(' || quote_literal(pixelgeom) || 
                    ', ' || args[9] || ')) val
                    FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' ||
                    quote_ident(args[12]) || ')) foo';

        ELSE
            query = 'SELECT NULL';
        END IF;
--RAISE NOTICE 'query = %', query;
        EXECUTE query INTO result;
        RETURN result;
    END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

-----------------------------------------------------------
-- Callback function computing a value for the whole pixel shape
CREATE OR REPLACE FUNCTION ST_ExtractPixelValue4ma(
    pixel double precision[][][], 
    pos int[][], 
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

--RAISE NOTICE 'val = %', pixel[1][1][1];        
--RAISE NOTICE 'y = %, x = %', pos[0][1], pos[0][2];        
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
	                                pos[0][1]::integer, -- x coordinate of the current pixel
	                                pos[0][2]::integer  -- y coordinate of the current pixel
	                               ));
        -- Query the appropriate value
        IF args[14] = 'COUNT_OF_POLYGONS' THEN -- Number of polygons intersecting the pixel
            query = 'SELECT count(*) FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE (ST_GeometryType(' || quote_ident(args[12]) || ') = ''ST_Polygon'' OR 
                             ST_GeometryType(' || quote_ident(args[12]) || ') = ''ST_MultiPolygon'') AND 
                            ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                            || quote_ident(args[12]) || ') AND 
                            ST_Area(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || 
                            quote_ident(args[12]) || ')) > 0.0000000001';
                    
        ELSEIF args[14] = 'COUNT_OF_LINESTRINGS' THEN -- Number of linestring intersecting the pixel
            query = 'SELECT count(*) FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE (ST_GeometryType(' || quote_ident(args[12]) || ') = ''ST_LineString'' OR 
                             ST_GeometryType(' || quote_ident(args[12]) || ') = ''ST_MultiLineString'') AND
                             ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                             || quote_ident(args[12]) || ') AND 
                             ST_Length(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' || 
                             quote_ident(args[12]) || ')) > 0.0000000001';
                    
        ELSEIF args[14] = 'COUNT_OF_POINTS' THEN -- Number of points intersecting the pixel
            query = 'SELECT count(*) FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE (ST_GeometryType(' || quote_ident(args[12]) || ') = ''ST_Point'' OR 
                             ST_GeometryType(' || quote_ident(args[12]) || ') = ''ST_MultiPoint'') AND
                             ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                             || quote_ident(args[12]) || ')';
                    
        ELSEIF args[14] = 'COUNT_OF_GEOMETRIES' THEN -- Number of geometries intersecting the pixel
            query = 'SELECT count(*) FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                    || quote_ident(args[12]) || ')';
                    
        ELSEIF args[14] = 'VALUE_OF_BIGGEST' THEN -- Value of the geometry covering the biggest area in the pixel
            query = 'SELECT ' || quote_ident(args[13]) || 
                    ' val FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                    || quote_ident(args[12]) || 
                    ') ORDER BY ST_Area(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), 
                                                        ' || quote_ident(args[12]) || 
                    ')) DESC, val DESC LIMIT 1';

        ELSEIF args[14] = 'VALUE_OF_MERGED_BIGGEST' THEN -- Value of the combined geometry covering the biggest area in the pixel
            query = 'SELECT val FROM (SELECT ' || quote_ident(args[13]) || ' val, 
                                            sum(ST_Area(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) 
                                            || ', '|| args[9] || '), ' || quote_ident(args[12]) ||
                    '))) sumarea FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                    || quote_ident(args[12]) || 
                    ') GROUP BY val) foo ORDER BY sumarea DESC, val DESC LIMIT 1';

        ELSEIF args[14] = 'MIN_AREA' THEN -- Area of the geometry covering the smallest area in the pixel
            query = 'SELECT area FROM (SELECT ST_Area(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', ' 
                                                      || args[9] || '), ' || quote_ident(args[12]) || 
                    ')) area FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                    || quote_ident(args[12]) || 
                    ')) foo WHERE area > 0.0000000001 ORDER BY area LIMIT 1';

        ELSEIF args[14] = 'VALUE_OF_MERGED_SMALLEST' THEN -- Value of the combined geometry covering the biggest area in the pixel
            query = 'SELECT val FROM (SELECT ' || quote_ident(args[13]) || ' val, 
                                             sum(ST_Area(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '
                                             || args[9] || '), ' || quote_ident(args[12]) ||
                    '))) sumarea FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                    || quote_ident(args[12]) || 
                    ') AND ST_Area(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                                                                     || quote_ident(args[12]) || ')) > 0.0000000001 
                      GROUP BY val) foo ORDER BY sumarea ASC, val DESC LIMIT 1';

        ELSEIF args[14] = 'SUM_OF_AREAS' THEN -- Sum of areas intersecting with the pixel (no matter the value)
            query = 'SELECT sum(ST_Area(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                                                                          || quote_ident(args[12]) ||
                    '))) sumarea FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                    || quote_ident(args[12]) || 
                    ')';

        ELSEIF args[14] = 'SUM_OF_LENGTHS' THEN -- Sum of lengths intersecting with the pixel (no matter the value)
            query = 'SELECT sum(ST_Length(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                                                                          || quote_ident(args[12]) ||
                    '))) sumarea FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                    || quote_ident(args[12]) || 
                    ')';

        ELSEIF args[14] = 'PROPORTION_OF_COVERED_AREA' THEN -- Proportion of the pixel covered by polygons (no matter the value)
            query = 'SELECT ST_Area(ST_Union(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                                                                               || quote_ident(args[12]) ||
                    ')))/ST_Area(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || ')) sumarea 
                     FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                    ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                    || quote_ident(args[12]) || 
                    ')';

        ELSEIF args[14] = 'AREA_WEIGHTED_MEAN_OF_VALUES' THEN -- Mean of every geometry weighted by the area they cover
            query = 'SELECT CASE 
                              WHEN sum(area) = 0 THEN 0 
                              ELSE sum(area * val) / 
                                   greatest(sum(area), 
                                            ST_Area(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '))
                                           )
                            END 
                     FROM (SELECT ' || quote_ident(args[13]) || ' val, 
                                 ST_Area(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                                                         || quote_ident(args[12]) || ')) area 
                           FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                         ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                         || quote_ident(args[12]) || 
                    ')) foo';
      
        ELSEIF args[14] = 'AREA_WEIGHTED_MEAN_OF_VALUES_2' THEN -- Mean of every geometry weighted by the area they cover
            query = 'SELECT CASE 
                              WHEN sum(area) = 0 THEN 0 
                              ELSE sum(area * val) / sum(area)
                            END 
                     FROM (SELECT ' || quote_ident(args[13]) || ' val, 
                                 ST_Area(ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                                                         || quote_ident(args[12]) || ')) area 
                           FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                         ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                         || quote_ident(args[12]) || 
                    ')) foo';
        ---------------------------------------------------------------- 
        -- Methods for the ST_GlobalRasterUnion() function
        ---------------------------------------------------------------- 
        ELSEIF args[14] = 'AREA_WEIGHTED_SUM_OF_RASTER_VALUES' THEN -- Sum of every pixel value weighted by the area they cover
            query = 'SELECT sum(ST_Area((gv).geom) * (gv).val)
                     FROM (SELECT ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', ' || 
                                                                   args[9] || '), ' || quote_ident(args[12]) || ') gv 
                           FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                         ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                         || quote_ident(args[12]) || 
                    ')) foo';

        ELSEIF args[14] = 'SUM_OF_AREA_PROPORTIONAL_RASTER_VALUES' THEN -- Sum of the proportion of pixel values intersecting with the pixel
            query = 'SELECT sum(ST_Area((gv).geom) * (gv).val / geomarea)
                     FROM (SELECT ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', ' || 
                                                                  args[9] || '), ' || quote_ident(args[12]) || ') gv, abs(ST_ScaleX(' || quote_ident(args[12]) || ') * ST_ScaleY(' || quote_ident(args[12]) || ')) geomarea
                           FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                         ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                         || quote_ident(args[12]) || 
                    ')) foo1';
                    
        ELSEIF args[14] = 'AREA_WEIGHTED_MEAN_OF_RASTER_VALUES' THEN -- Mean of every pixel value weighted by the maximum area they cover
            query = 'SELECT CASE 
                              WHEN sum(area) = 0 THEN NULL 
                              ELSE sum(area * val) / 
                                   greatest(sum(area), 
                                            ST_Area(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '))
                                           ) 
                            END 
                     FROM (SELECT ST_Area((gv).geom) area, (gv).val val
                           FROM (SELECT ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', ' || 
                                                                        args[9] || '), ' || quote_ident(args[12]) || ') gv 
                                 FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                               ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                         || quote_ident(args[12]) || 
                    ')) foo1) foo2';

        ELSEIF args[14] = 'AREA_WEIGHTED_MEAN_OF_RASTER_VALUES_2' THEN -- Mean of every pixel value weighted by the area they cover
            query = 'SELECT CASE 
                              WHEN sum(area) = 0 THEN NULL 
                              ELSE sum(area * val) / sum(area)
                            END 
                     FROM (SELECT ST_Area((gv).geom) area, (gv).val val
                           FROM (SELECT ST_Intersection(ST_GeomFromText(' || quote_literal(pixelgeom) || ', ' || 
                                                                        args[9] || '), ' || quote_ident(args[12]) || ') gv 
                                 FROM ' || quote_ident(args[10]) || '.' || quote_ident(args[11]) || 
                               ' WHERE ST_Intersects(ST_GeomFromText(' || quote_literal(pixelgeom) || ', '|| args[9] || '), ' 
                         || quote_ident(args[12]) || 
                    ')) foo1) foo2';

        ELSE
            query = 'SELECT NULL';
        END IF;
--RAISE NOTICE 'query = %', query;
        EXECUTE query INTO result;
        RETURN result;
    END; 
$$ LANGUAGE 'plpgsql' IMMUTABLE;

-----------------------------------------------------------
-- Main ST_ExtractToRaster function
CREATE OR REPLACE FUNCTION ST_ExtractToRaster(
    rast raster, 
    band integer, 
    schemaname name, 
    tablename name, 
    geomrastcolumnname name, 
    valuecolumnname name, 
    method text DEFAULT 'MEAN_OF_VALUES_AT_PIXEL_CENTROID'
)
RETURNS raster AS $$ 
    DECLARE
        query text;
        newrast raster;
        fct2call text;
        newvaluecolumnname text;
        intcount int;
    BEGIN
        -- Determine the name of the right callback function
        IF right(method, 5) = 'TROID' THEN
            fct2call = 'ST_ExtractPixelCentroidValue4ma';
        ELSE
            fct2call = 'ST_ExtractPixelValue4ma';
        END IF;

        IF valuecolumnname IS NULL THEN
            newvaluecolumnname = 'null';
        ELSE
            newvaluecolumnname = quote_literal(valuecolumnname);
        END IF;
        
        query = 'SELECT count(*) FROM "' || schemaname || '"."' || tablename || '" WHERE ST_Intersects($1, ' || geomrastcolumnname || ')';

        EXECUTE query INTO intcount USING rast;
        IF intcount = 0 THEN
            -- if the method should return 0 when there is no geometry involved, return a raster containing only zeros
            IF left(method, 6) = 'COUNT_' OR
               method = 'SUM_OF_AREAS' OR
               method = 'SUM_OF_LENGTHS' OR
               method = 'PROPORTION_OF_COVERED_AREA' THEN
                RETURN ST_AddBand(ST_DeleteBand(rast, band), ST_AddBand(ST_MakeEmptyRaster(rast), ST_BandPixelType(rast, band), 0, ST_BandNodataValue(rast, band)), 1, band);
            ELSE
                RETURN ST_AddBand(ST_DeleteBand(rast, band), ST_AddBand(ST_MakeEmptyRaster(rast), ST_BandPixelType(rast, band), ST_BandNodataValue(rast, band), ST_BandNodataValue(rast, band)), 1, band);
            END IF;
        END IF;

        query = 'SELECT ST_MapAlgebra($1, 
                                      $2, 
                                      ''' || fct2call || '(double precision[], integer[], text[])''::regprocedure, 
                                      ST_BandPixelType($1, $2),
                                      null,
                                      null,
                                      null,
                                      null,
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
                                      quote_literal(geomrastcolumnname) || ', ' ||
                                      newvaluecolumnname || ', ' ||
                                      quote_literal(upper(method)) || '
                                     ) rast';
--RAISE NOTICE 'query = %', query;
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
-- ST_ExtractToRaster variant defaulting valuecolumnname to null
CREATE OR REPLACE FUNCTION ST_ExtractToRaster(
    rast raster,
    band integer,
    schemaname name, 
    tablename name, 
    geomcolumnname name, 
    method text DEFAULT 'MEAN_OF_VALUES_AT_PIXEL_CENTROID'
)
RETURNS raster AS $$
    SELECT ST_ExtractToRaster($1, $2, $3, $4, $5, null, $6)
$$ LANGUAGE 'sql';
---------------------------------------------------------------------
-- ST_ExtractToRaster variant defaulting band number to 1 and valuecolumnname to null
CREATE OR REPLACE FUNCTION ST_ExtractToRaster(
    rast raster,
    schemaname name, 
    tablename name, 
    geomcolumnname name, 
    method text DEFAULT 'MEAN_OF_VALUES_AT_PIXEL_CENTROID'
)
RETURNS raster AS $$
    SELECT ST_ExtractToRaster($1, 1, $2, $3, $4, null, $5)
$$ LANGUAGE 'sql';
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ST_GlobalRasterUnion
--
--   schemaname text       - Name of the schema containing the table from which to union rasters.
--   tablename text        - Name of the table from which to union rasters.
--   rastercolumnname text - Name of the column containing the raster to union.
--   pixeltype             - Pixel type of the new raster. Can be: 1BB, 2BUI, 4BUI, 8BSI, 8BUI, 
--                           16BSI, 16BUI, 32BSI, 32BUI, 32BF, 64BF
--   nodataval             - Nodata value of the new raster.
--
-- RETURNS raster
--
-- Returns a raster being the union of all raster of a raster table.
--
-- The source raster table should be tiled and indexed for optimal performance. 
-- Smaller tile sizes generally give better performance.
--
-- Differs from ST_Union in many ways:
-- 
--  - Takes the names of a schema, a table and a raster column instead of rasters 
--    themselves. That means the function works on a whole table and can not be used 
--    on a selection or a group of rasters (unless you build a view on the table and 
--    you pass the name of the view in place of the name of the table).
--
--  - Works with unaligned rasters. The extent of the resulting raster is computed
--    from the global extent of the table and the pixel size is the minimum of all 
--    pixel sizes of the rasters in the table.
--
--  - Offers more methods for computing the value of each pixel. More can be 
--    easily implemented in the ST_ExtractPixelCentroidValue4ma and 
--    ST_ExtractPixelValue4ma functions.
--
--  - Because methods are implemented in PL/pgSQL and involve a SQL query for 
--    each pixel, ST_GlobalUnionToRaster will generally be way slower than 
--    ST_Union. It is however more flexible, allows more value determination 
--    methods and even might be faster on big coverages because it does not 
--    require internal memory copy of progressively bigger and bigger raster 
--    pieces.
--
-- When pixeltype is null, it is assumed to be identical for all rasters. If not, 
-- the maximum of all pixel type stings is used. In some cases, this might not 
-- make sense at all... e.g. Most rasters are 32BUI, one is 8BUI and 8BUI is used.
--
-- When nodataval is null, nodata value is assumed to be identical for all rasters. 
-- If not, the minimum of all raster nodata value is used.
--
-- For now, those methods are implemented:
--
--   - COUNT_OF_RASTER_VALUES_AT_PIXEL_CENTROID: Number of non null raster value intersecting with the 
--                                               pixel centroid.
--
--   - FIRST_RASTER_VALUE_AT_PIXEL_CENTROID: First raster value intersecting with the 
--                                           pixel centroid. This is the default.
--
--   - MIN_OF_RASTER_VALUES_AT_PIXEL_CENTROID: Minimum of all raster values intersecting with the 
--                                             pixel centroid.
--
--   - MAX_OF_RASTER_VALUES_AT_PIXEL_CENTROID: Maximum of all raster values intersecting with the 
--                                             pixel centroid.
--
--   - SUM_OF_RASTER_VALUES_AT_PIXEL_CENTROID: Sum of all raster values intersecting with the 
--                                             pixel centroid.
--
--   - MEAN_OF_RASTER_VALUES_AT_PIXEL_CENTROID: Average of all raster values intersecting 
--                                              with the pixel centroid.
--
--   - STDDEVP_OF_RASTER_VALUES_AT_PIXEL_CENTROID: Population standard deviation of all raster 
--                                                 values intersecting with the pixel centroid.
--
--   - RANGE_OF_RASTER_VALUES_AT_PIXEL_CENTROID: Range (maximun - minimum) of raster values 
--                                               intersecting with the pixel centroid.
--
--   - For the next methods, let's say that 2 pixels are intersecting with the target pixel and that:
--         - ia1 and ia2 are the areas of the intersection between the source pixel and the target pixel,
--         - v1 and v2 are the values of the source pixels,
--         - sa1 and sa2 are the areas of the sources pixels,
--         - ta is the area of the target pixel,
--         - x is the value assigned to the target pixel.
--
--   - AREA_WEIGHTED_SUM_OF_RASTER_VALUES: Sum of all source pixel values weighted by the proportion of 
--                                         the target pixel they cover.
--                                         This is the first part of the area weighted mean.
--                                         x = ia1 * v1 + ia2 * v2
--
--   - SUM_OF_AREA_PROPORTIONAL_RASTER_VALUES: Sum of all pixel values weighted by the proportion of their 
--                                             intersecting parts with the source pixel.
--                                             x = (ia1 * v1)/sa1 + (ia2 * v2)/sa2
--
--   - AREA_WEIGHTED_MEAN_OF_RASTER_VALUES: Mean of all source pixel values weighted by the proportion of 
--                                          the target pixel they cover. 
--                                          The weighted sum is divided by the maximum between the 
--                                          area of the pixel and the sum of all the weighted pixel 
--                                          areas. i.e. Target pixels at the edge of the source rasters   
--                                          global extent are weighted by the proportion of the covering area.
--                                          x = (ia1 * v1 + ia2 * v2)/max(ia1 + ia2, ta)
--                                          
--   - AREA_WEIGHTED_MEAN_OF_RASTER_VALUES_2: Mean of all source pixel values weighted by the proportion of 
--                                            the target pixel they cover. 
--                                            The weighted sum is divided by the sum of all the weighted 
--                                            pixel areas. i.e. Target pixels at the edge of the source rasters   
--                                            global extent take the full weight of their area.
--                                            x = (ia1 * v1 + ia2 * v2)/(ia1 + ia2)
--                                              
-- Self contained and typical example:
--
-- We first create a table of geometries:
-- 
-- DROP TABLE IF EXISTS test_globalrasterunion;
-- CREATE TABLE test_globalrasterunion AS
-- SELECT ST_CreateIndexRaster(ST_MakeEmptyRaster(5, 5, 0, 0, 1, 1, 0, 0), '8BUI') rast
-- UNION ALL
-- SELECT ST_CreateIndexRaster(ST_MakeEmptyRaster(6, 5, 2.8, 2.8, 0.85, 0.85, 0, 0), '8BUI');
--
-- We then extract the values to a raster:
--
-- SELECT ST_GlobalRasterUnion('public', 'test_globalrasterunion', 'rast', 'FIRST_RASTER_VALUE_AT_PIXEL_CENTROID') rast;
--
-- The equivalent statement using ST_Union would be:
--
-- SELECT ST_Union(rast, 'FIRST') rast
-- FROM public.test_globalrasterunion
--
-- But it would fail because the two rasters are not properly aligned.
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 10/07/2013 v. 1.11
-----------------------------------------------------------
CREATE OR REPLACE FUNCTION ST_GlobalRasterUnion(
    schemaname name, 
    tablename name, 
    rastercolumnname name,
    method text DEFAULT 'FIRST_RASTER_VALUE_AT_PIXEL_CENTROID',
    pixeltype text DEFAULT null,
    nodataval double precision DEFAULT null
)
RETURNS raster AS $$ 
    DECLARE
        query text;
        newrast raster;
        fct2call text;
        pixeltypetxt text;
        nodatavaltxt text;
    BEGIN
        IF right(method, 5) = 'TROID' THEN
            fct2call = 'ST_ExtractPixelCentroidValue4ma';
        ELSE
            fct2call = 'ST_ExtractPixelValue4ma';
        END IF;
        IF pixeltype IS NULL THEN
            pixeltypetxt = 'ST_BandPixelType(' || quote_ident(rastercolumnname) || ')';
        ELSE
            pixeltypetxt = '''' || pixeltype || '''::text';
        END IF;
        IF nodataval IS NULL THEN
            nodatavaltxt = 'ST_BandNodataValue(' || quote_ident(rastercolumnname) || ')';
        ELSE
            nodatavaltxt = nodataval;
        END IF;
        query = 'SELECT ST_MapAlgebra(rast, 
                                      1,
                                      ''' || fct2call || '(double precision[], integer[], text[])''::regprocedure, 
                                      ST_BandPixelType(rast, 1),
                                      null,
                                      null,
                                      null,
                                      null,
                                      ST_Width(rast)::text,
                                      ST_Height(rast)::text,
                                      ST_UpperLeftX(rast)::text,
                                      ST_UpperLeftY(rast)::text,
                                      ST_ScaleX(rast)::text,
                                      ST_ScaleY(rast)::text,
                                      ST_SkewX(rast)::text,
                                      ST_SkewY(rast)::text,
                                      ST_SRID(rast)::text,' || 
                                      quote_literal(schemaname) || ', ' ||
                                      quote_literal(tablename) || ', ' ||
                                      quote_literal(rastercolumnname) || ', 
                                      null' || ', ' ||
                                      quote_literal(upper(method)) || '
                                     ) rast
                 FROM (SELECT ST_AsRaster(ST_Union(rast::geometry), 
                                          min(scalex),
                                          min(scaley),
                                          min(gridx),
                                          min(gridy),
                                          max(pixeltype),
                                          0,
                                          min(nodataval)
                                         ) rast
                       FROM (SELECT ' || quote_ident(rastercolumnname) || ' rast,
                                    ST_ScaleX(' || quote_ident(rastercolumnname) || ') scalex, 
                                    ST_ScaleY(' || quote_ident(rastercolumnname) || ') scaley, 
                                    ST_UpperLeftX(' || quote_ident(rastercolumnname) || ') gridx, 
                                    ST_UpperLeftY(' || quote_ident(rastercolumnname) || ') gridy, 
                                    ' || pixeltypetxt || ' pixeltype, 
                                    ' || nodatavaltxt || ' nodataval
                             FROM ' || quote_ident(schemaname) || '.' || quote_ident(tablename) || ' 
                            ) foo1
                      ) foo2';
        EXECUTE query INTO newrast;
        RETURN newrast;
    END; 
$$ LANGUAGE 'plpgsql' IMMUTABLE;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ST_BufferedUnion
--
--   geom geometry            - Set of geometry to union.
--   bufsize double precision - Radius of the buffer to add to every geometry 
--                              before union (and to remove after).
--
-- RETURNS geometry
--
-- Aggregate function alternative to ST_Union making a buffer around 
-- each geometry before unioning and removing it afterward. Used 
-- when ST_Union leaves internal undesirable vertexes after a complex 
-- union (which is sometimes the case when unioning all the extents of 
-- a raster coverage loaded with raster2pgsql), when ST_Union fails or 
-- when remaining holes have to be removed from the resulting union.
--
-- ST_BufferedUnion is slower than ST_Union but the result is often cleaner
-- (no garbage vertexes or linestrings)
--
-- Self contained example (to be compared with the result of ST_Union):
--
-- SELECT ST_BufferedUnion(geom, 0.0005) 
-- FROM (SELECT 1 id, 'POLYGON((0 0,10 0,10 -9.9999,0 -10,0 0))'::geometry geom
--       UNION ALL
--       SELECT 2 id, 'POLYGON((10 0,20 0,20 -9.9999,10 -10,10 0))'::geometry
--       UNION ALL
--       SELECT 3 id, 'POLYGON((0 -10,10 -10.0001,10 -20,0 -20,0 -10))'::geometry
--       UNION ALL
--       SELECT 4 id, 'POLYGON((10 -10,20 -10,20 -20,10 -20,10 -10))'::geometry
--      ) foo
--
-- Typical example:
-- 
-- SELECT ST_BufferedUnion(rast::geometry) geom
-- FROM rastertable
--
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 10/18/2013 v. 1.13
-----------------------------------------------------------
-- ST_BufferedUnion aggregate state function
CREATE OR REPLACE FUNCTION _ST_BufferedUnion_StateFN(
    gv geomval, 
    geom geometry, 
    bufsize double precision DEFAULT 0.0
)
RETURNS geomval AS $$
    SELECT CASE WHEN $1 IS NULL AND $2 IS NULL THEN
                    null
                WHEN $1 IS NULL THEN 
                    (ST_Buffer($2, CASE WHEN $3 IS NULL THEN 0.0 ELSE $3 END, 'endcap=square join=mitre'), 
                     CASE WHEN $3 IS NULL THEN 0.0 ELSE $3 END
                    )::geomval
                WHEN $2 IS NULL THEN
                    $1
                ELSE (ST_Union(($1).geom, 
	                       ST_Buffer($2, CASE WHEN $3 IS NULL THEN 0.0 ELSE $3 END, 'endcap=square join=mitre')
	                      ), 
	              ($1).val
	             )::geomval
	   END;
$$ LANGUAGE 'sql' IMMUTABLE;

-----------------------------------------------------------
-- ST_BufferedUnion aggregate final function
CREATE OR REPLACE FUNCTION _ST_BufferedUnion_FinalFN(
    gv geomval
)
RETURNS geometry AS $$
    SELECT ST_Buffer(($1).geom, -($1).val, 'endcap=square join=mitre')
$$ LANGUAGE 'sql' IMMUTABLE STRICT;

-----------------------------------------------------------
-- ST_BufferedUnion aggregate definition
CREATE AGGREGATE ST_BufferedUnion(geometry, double precision)
(
    SFUNC = _ST_BufferedUnion_StateFN,
    STYPE = geomval,
    FINALFUNC = _ST_BufferedUnion_FinalFN
);
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ST_NBiggestExteriorRings
--
--   geom geometry - Geometry from which to extract exterior rings.
--   nbrings int   - Number of rings to extract.
--   comptype text - Determine how 'biggest' is interpreted. Can be 'AREA' or 'NBPOINTS'.
--
-- RETURNS set of geometry
--
-- Returns the 'nbrings' biggest exterior rings of the provided geometry. Biggest
-- can be defined in terms of the area of the ring (AREA) or in terms of the 
-- total number of vertexes in the ring (NBPOINT).
--
-- Self contained example:
--
-- SELECT ST_NBiggestExteriorRings(
--          ST_GeomFromText('MULTIPOLYGON( ((0 0, 0 5, 0 10, 8 10, 8 0, 0 0)), 
--                                         ((20 0, 20 5, 20 10, 30 10, 30 0, 20 0)), 
--                                         ((40 0, 40 10, 52 10, 52 0, 40 0)) )'), 
--          2, 'NBPOINTS') geom
--
-- Typical example:
--
-- SELECT ST_NBiggestExteriorRings(ST_Union(geom), 4) geom
-- FROM geomtable
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 10/18/2013 v. 1.13
-----------------------------------------------------------
CREATE OR REPLACE FUNCTION ST_NBiggestExteriorRings(
    ingeom geometry, 
    nbrings integer, 
    comptype text DEFAULT 'AREA'
)
RETURNS SETOF geometry AS $$
    DECLARE
    BEGIN
	IF upper(comptype) = 'AREA' THEN
	    RETURN QUERY SELECT ring 
	                 FROM (SELECT ST_MakePolygon(ST_ExteriorRing((ST_Dump(ingeom)).geom)) ring
	                      ) foo
	                 ORDER BY ST_Area(ring) DESC LIMIT nbrings;
	ELSIF upper(comptype) = 'NBPOINTS' THEN
	    RETURN QUERY SELECT ring 
	                 FROM (SELECT ST_MakePolygon(ST_ExteriorRing((ST_Dump(ingeom)).geom)) ring
	                      ) foo
	                 ORDER BY ST_NPoints(ring) DESC LIMIT nbrings;
	ELSE
	    RAISE NOTICE 'ST_NBiggestExteriorRings: Unsupported comparison type: ''%''. Try ''AREA'' or ''NBPOINTS''.', comptype;
	    RETURN;
	END IF;
    END;
$$ LANGUAGE 'plpgsql';
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ST_BufferedSmooth
--
--   geom geometry            - Geometry to smooth.
--   bufsize double precision - Radius of the buffer to add and remove to every 
--                              geometry.
--
-- RETURNS geometry
--
-- Returns a smoothed version fo the geometry. The smoothing is done by 
-- making a buffer around the geometry and removing it afterward.
--
-- Note that topology will not be preserved if this function is applied on a 
-- topological set of geometries.
--
-- Self contained example:
--
-- SELECT ST_BufferedSmooth(ST_GeomFromText('POLYGON((-2 1, -5 5, -1 2, 0 5, 1 2, 
-- 5 5, 2 1, 5 0, 2 -1, 5 -5, 1 -2, 0 -5, -1 -2, -5 -5, -2 -1, -5 0, -2 1))'), 1)
--
-- Typical example:
--
-- SELECT ST_BufferedSmooth(geom, 4) geom
-- FROM geomtable
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 10/18/2013 v. 1.13
-----------------------------------------------------------
CREATE OR REPLACE FUNCTION ST_BufferedSmooth(
    geom geometry, 
    bufsize double precision DEFAULT 0
)
RETURNS geometry AS $$
    SELECT ST_Buffer(ST_Buffer($1, $2), -$2)
$$ LANGUAGE 'sql' IMMUTABLE;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ST_DifferenceAgg
--
--   geom1 geometry - Geometry from which to remove subsequent geometries
--                    in the aggregate.
--   geom2 geometry - Geometry to remove from geom1.
--
-- RETURNS geometry
--
-- Returns the first geometry after having removed all the subsequent geometries in
-- the aggregate. This function is used to remove overlaps in a table of polygons.
--
-- Refer to the self contained example below. Each geometry MUST have a unique ID 
-- and, if the table contains a huge number of geometries, it should be indexed.
--
-- Self contained and typical example removing, from every geometry, all
-- the overlapping geometries having a bigger area. i.e larger polygons have priority:
--
-- WITH overlappingtable AS (
--   SELECT 1 id, ST_GeomFromText('POLYGON((0 1, 3 2, 3 0, 0 1))') geom
--   UNION ALL
--   SELECT 2 id, ST_GeomFromText('POLYGON((1 1, 3.8 2, 4 0, 1 1))')
--   UNION ALL
--   SELECT 3 id, ST_GeomFromText('POLYGON((2 1, 4.6 2, 5 0, 2 1))')
--   UNION ALL
--   SELECT 4 id, ST_GeomFromText('POLYGON((3 1, 5.4 2, 6 0, 3 1))')
--   UNION ALL
--   SELECT 5 id, ST_GeomFromText('POLYGON((3 1, 5.4 2, 6 0, 3 1))')
-- )
-- SELECT a.id, ST_DifferenceAgg(a.geom, b.geom) geom
-- FROM overlappingtable a, 
--      overlappingtable b
-- WHERE a.id = b.id OR 
--       ((ST_Contains(a.geom, b.geom) OR 
--         ST_Contains(b.geom, a.geom) OR 
--         ST_Overlaps(a.geom, b.geom)) AND 
--        (ST_Area(a.geom) < ST_Area(b.geom) OR 
--         (ST_Area(a.geom) = ST_Area(b.geom) AND 
--          a.id < b.id)))
-- GROUP BY a.id
-- HAVING ST_Area(ST_DifferenceAgg(a.geom, b.geom)) > 0.00001 AND NOT ST_IsEmpty(ST_DifferenceAgg(a.geom, b.geom));
--
-- The HAVING clause of the query makes sure that very small and empty remains not included in the result.
--
--
-- In some cases you may want to use the polygons ids instead of the 
-- polygons areas to decide which one is removed from the other one.
-- You first have to ensure ids are unique for this to work. In that  
-- case you would simply replace:
--
--     ST_Area(a.geom) < ST_Area(b.geom) OR 
--     (ST_Area(a.geom) = ST_Area(b.geom) AND a.id < b.id)
--
-- with:
--
--     a.id < b.id
--
-- to cut all the polygons with greatest ids from the polygons with 
-- smallest ids.
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 10/18/2013 v. 1.14
-----------------------------------------------------------
-- ST_DifferenceAgg aggregate state function
CREATE OR REPLACE FUNCTION _ST_DifferenceAgg_StateFN(
    geom1 geomval, 
    geom2 geometry, 
    geom3 geometry
)
RETURNS geomval AS $$
    DECLARE
       newgeom geomval;
       differ geometry;
       equals boolean;
    BEGIN
        -- First pass: geom1 is null
        IF geom1 IS NULL AND NOT ST_IsEmpty(geom2) AND ST_Area(geom3) > 0.0000001 THEN
            newgeom = CASE 
                        WHEN ST_Equals(geom2, geom3) THEN (geom2, 1) 
                        ELSE (ST_Difference(geom2, geom3), 0)
                      END;
        ELSIF NOT ST_IsEmpty((geom1).geom) AND ST_Area(geom3) > 0.0000001 THEN
            equals = ST_Equals(geom2, geom3);
            IF NOT equals THEN
                BEGIN
                    differ = ST_Difference((geom1).geom, geom3);
                EXCEPTION
            	WHEN OTHERS THEN
	                BEGIN
	                    differ = ST_Difference(ST_Buffer((geom1).geom, 0.000001), ST_Buffer(geom3, 0.000001));
	                EXCEPTION
		            WHEN OTHERS THEN
		                BEGIN
		                    differ = ST_Difference(ST_Buffer((geom1).geom, 0.00001), ST_Buffer(geom3, 0.00001));
		                EXCEPTION
		            	WHEN OTHERS THEN
			                differ = (geom1).geom;
		                END;
	                END;
                END;
            END IF;
            newgeom = CASE 
                        WHEN equals AND (geom1).val = 0 THEN ((geom1).geom, 1)
                        ELSE (differ, (geom1).val)
                      END;
        ELSE
            newgeom = geom1;
        END IF;

        IF NOT ST_IsEmpty((newgeom).geom) THEN
            newgeom = (ST_CollectionExtract((newgeom).geom, 3), (newgeom).val);
        END IF;

        IF (newgeom).geom IS NULL THEN
            newgeom = (ST_GeomFromText('MULTIPOLYGON EMPTY', ST_SRID(geom2)), (newgeom).val);
        END IF;

        RETURN newgeom;
    END;
$$ LANGUAGE plpgsql IMMUTABLE;
-----------------------------------------------------------
-- ST_DifferenceAgg aggregate final function
CREATE OR REPLACE FUNCTION _ST_DifferenceAgg_FinalFN(gv geomval)
  RETURNS geometry AS $$ 
    SELECT ($1).geom 
$$ LANGUAGE sql VOLATILE STRICT;
-----------------------------------------------------------
-- ST_DifferenceAgg aggregate
CREATE AGGREGATE ST_DifferenceAgg(geometry, geometry) (
  SFUNC=_ST_DifferenceAgg_StateFN,
  FINALFUNC=_ST_DifferenceAgg_FinalFN,
  STYPE=geomval
);
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ST_TrimMulti
--
--   geom geometry - Multipolygon or geometry collection to trim.
--   minarea double precision - Minimal area of an inner polygon to be kept in 
--                              the geometry.
--
-- RETURNS geometry
--
-- Returns a multigeometry from which simple geometries having an area smaller 
-- than the tolerance parameter have been removed. This includes points and linestrings 
-- when a geometry collection is provided. When no tolerance is provided, minarea is 
-- defaulted to 0.0 and this function is equivalent to ST_CollectionExtract(geom, 3).
--
-- This function is used by the ST_SplitAgg state function.
--
-- Self contained and typical example:
--
-- SELECT ST_TrimMulti(
--         ST_GeomFromText('MULTIPOLYGON(((2 2, 2 3, 2 4, 2 2)),
--                                       ((0 0, 0 1, 1 1, 1 0, 0 0)))'), 0.00001) geom
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 13/11/2013 v. 1.16
-----------------------------------------------------------
CREATE OR REPLACE FUNCTION ST_TrimMulti(
    geom geometry, 
    minarea double precision DEFAULT 0.0
)
RETURNS geometry AS $$
    SELECT ST_Union(newgeom) 
    FROM (SELECT ST_CollectionExtract((ST_Dump($1)).geom, 3) newgeom
         ) foo 
    WHERE ST_Area(newgeom) > $2;
$$ LANGUAGE 'sql' IMMUTABLE;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ST_SplitAgg
--
--   geom1 geometry - Geometry to split.
--   geom2 geometry - Geometry used to split the first geometry.
--   tolerance - Minimal area necessary for split slivers to be kept in the result.
--
-- RETURNS geometry[]
--
-- Returns the first geometry as a set of geometries after being split by all 
-- the second geometries being part of the aggregate.
--
-- This function is used to remove overlaps in a table of polygons or to generate 
-- the equivalent of a ArcGIS union (see http://trac.osgeo.org/postgis/wiki/UsersWikiExamplesOverlayTables).
-- As it does not involve the usion of all the polygons (or the extracted linestring) 
-- of the table, it works much better on very large tables than the solutions 
-- provided in the wiki.
--
--
-- Self contained and typical example:
--
-- WITH geomtable AS (
-- SELECT 1 id, ST_GeomFromText('POLYGON((0 0, 0 2, 2 2, 2 0, 0 0), (0.2 0.5, 0.2 1.5, 0.8 1.5, 0.8 0.5, 0.2 0.5))') geom
-- UNION ALL
-- SELECT 2 id, ST_GeomFromText('POLYGON((1 0.2, 1 1, 3 1, 3 0.2, 1 0.2))') geom
-- UNION ALL
-- SELECT 3 id, ST_GeomFromText('POLYGON((1.5 0.8, 1.5 1.2, 2.5 1.2, 2.5 0.8, 1.5 0.8))') geom
-- UNION ALL
-- SELECT 4 id, ST_GeomFromText('MULTIPOLYGON(((3 0, 3 2, 5 2, 5 0, 3 0)), ((4 3, 4 4, 5 4, 5 3, 4 3)))') geom
-- )
-- SELECT DISTINCT ON (geom) unnest(ST_SplitAgg(a.geom, b.geom, 0.00001)) geom 
-- FROM geomtable a, 
--      geomtable b
-- WHERE ST_Equals(a.geom, b.geom) OR 
--       ST_Contains(a.geom, b.geom) OR 
--       ST_Contains(b.geom, a.geom) OR 
--       ST_Overlaps(a.geom, b.geom)
-- GROUP BY a.geom;
--
-- The second example shows how to assign to each polygon the id of the biggest polygon:
--
-- WITH geomtable AS (
-- SELECT 1 id, ST_GeomFromText('POLYGON((0 0, 0 2, 2 2, 2 0, 0 0), (0.2 0.5, 0.2 1.5, 0.8 1.5, 0.8 0.5, 0.2 0.5))') geom
-- UNION ALL
-- SELECT 2 id, ST_GeomFromText('POLYGON((1 0.2, 1 1, 3 1, 3 0.2, 1 0.2))') geom
-- UNION ALL
-- SELECT 3 id, ST_GeomFromText('POLYGON((1.5 0.8, 1.5 1.2, 2.5 1.2, 2.5 0.8, 1.5 0.8))') geom
-- UNION ALL
-- SELECT 4 id, ST_GeomFromText('MULTIPOLYGON(((3 0, 3 2, 5 2, 5 0, 3 0)), ((4 3, 4 4, 5 4, 5 3, 4 3)))') geom
-- )
-- SELECT DISTINCT ON (geom) a.id, unnest(ST_SplitAgg(a.geom, b.geom, 0.00001)) geom
-- FROM geomtable a, 
--      geomtable b
-- WHERE ST_Equals(a.geom, b.geom) OR 
--       ST_Contains(a.geom, b.geom) OR 
--       ST_Contains(b.geom, a.geom) OR 
--       ST_Overlaps(a.geom, b.geom)
-- GROUP BY a.id
-- ORDER BY geom, max(ST_Area(a.geom)) DESC;
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 13/11/2013 v. 1.16
-----------------------------------------------------------
-- ST_SplitAgg aggregate state function
CREATE OR REPLACE FUNCTION _ST_SplitAgg_StateFN(
    geomarray geometry[], 
    geom1 geometry,
    geom2 geometry,
    tolerance double precision
)
RETURNS geometry[] AS $$
    DECLARE
        newgeomarray geometry[];
        geom3 geometry;
        newgeom geometry;
        geomunion geometry;
    BEGIN
        -- First pass: geomarray is null
       IF geomarray IS NULL THEN
            geomarray = array_append(newgeomarray, geom1);
        END IF;

        IF NOT geom2 IS NULL THEN
            -- 2) Each geometry in the array - geom2
            FOREACH geom3 IN ARRAY geomarray LOOP
                newgeom = ST_Difference(geom3, geom2);
                IF tolerance > 0 THEN
                    newgeom = ST_TrimMulti(newgeom, tolerance);
                END IF;
                IF NOT newgeom IS NULL AND NOT ST_IsEmpty(newgeom) THEN
                    newgeomarray = array_append(newgeomarray, newgeom);
                END IF;
            END LOOP;
            
        -- 3) gv1 intersecting each geometry in the array
            FOREACH geom3 IN ARRAY geomarray LOOP
                newgeom = ST_Intersection(geom3, geom2);
                IF tolerance > 0 THEN
                    newgeom = ST_TrimMulti(newgeom, tolerance);
                END IF;
                IF NOT newgeom IS NULL AND NOT ST_IsEmpty(newgeom) THEN
                    newgeomarray = array_append(newgeomarray, newgeom);
                END IF;
            END LOOP;
        ELSE
            newgeomarray = geomarray;
        END IF;
        RETURN newgeomarray;
    END;
$$ LANGUAGE plpgsql IMMUTABLE;

---------------------------------------
-- ST_SplitAgg aggregate variant state function defaulting tolerance to 0.0
CREATE OR REPLACE FUNCTION _ST_SplitAgg_StateFN(
    geomarray geometry[], 
    geom1 geometry,
    geom2 geometry
)
RETURNS geometry[] AS $$
    SELECT _ST_SplitAgg_StateFN($1, $2, $3, 0.0);
$$ LANGUAGE sql VOLATILE;

---------------------------------------
-- ST_SplitAgg aggregate
CREATE AGGREGATE ST_SplitAgg(geometry, geometry, double precision) (
    SFUNC=_ST_SplitAgg_StateFN,
    STYPE=geometry[]
);

---------------------------------------
-- ST_SplitAgg aggregate defaulting tolerance to 0.0
CREATE AGGREGATE ST_SplitAgg(geometry, geometry) (
    SFUNC=_ST_SplitAgg_StateFN,
    STYPE=geometry[]
);
