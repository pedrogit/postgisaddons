-------------------------------------------------------------------------------
-- PostGIS PL/pgSQL Add-ons - Main installation file
-- Version 1.6 for PostGIS 2.1.x and PostgreSQL 9.x
-- http://github.com/pedrogit/postgisaddons
-- 
-- The PostGIS add-ons attempt to gathers, in a single .sql file, useful and 
-- generic user contributed PL/pgSQL functions and to provide a fast and Agile 
-- way to release them. Files will be tagged with an incremental version number
-- for every significant change or addition. They should ALWAYS be left in a 
-- stable, installable and tested state.
--
-- Signatures and return values for existing functions should not change from 
-- minor revision to minor revision. New functions might be added though.
--
-- PostGIS PL/pgSQL Add-ons tries to make life as easy as possible for users
-- wishing to contribute their functions. This is why it limit itself to 
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
--   - Must be indented like the existing functions (4 spaces, no tabs).
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
-------------------------------------------------------------------------------

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
        FOR b IN 1..numband LOOP
            IF b != band THEN
                newrast := ST_AddBand(newrast, rast, b, NULL);
            END IF;
        END LOOP;
        RETURN newrast;
    END;
$$ LANGUAGE 'plpgsql';
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

        IF (gtype IS NULL OR (gtype != 'ST_Polygon') AND (gtype != 'ST_MultiPolygon')) THEN 
            RAISE NOTICE 'Attempting to get random points in a non polygon geometry';
            RETURN NEXT null;
            RETURN;
        END IF; 

        SELECT ST_XMin(geom), ST_XMax(geom), ST_YMin(geom), ST_YMax(geom), ST_SRID(geom) 
        INTO xmin, xmax, ymin, ymax, srid; 

        SELECT xmax - xmin, ymax - ymin 
        INTO xrange, yrange; 

        IF seed IS NOT NULL THEN 
            PERFORM setseed(seed); 
        END IF; 

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
$$ LANGUAGE 'plpgsql';
-------------------------------------------------------------------------------

