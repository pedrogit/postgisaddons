-------------------------------------------------------------------------------
-- PostGIS PL/pgSQL Add-ons - Main installation file
-- Version 1.x for PostGIS 2.1.x and PostgreSQL 9.x
-- https://github.com/pedrogit/postgisaddons/releases
-- 
-- The PostGIS add-ons attempt to gathers, in a single .sql file, useful and 
-- generic user contributed PL/pgSQL functions and to provide a fast and Agile 
-- way to release them. Files will be tagged with an incremental version number
-- for every significant change or addition. They should ALWAYS be left in a 
-- stable, installable and tested state.
--
-- Function signatures and return values should not change from minor revision to 
-- minor revision.
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
-- Remove a band from a raster. Band number starts at 1.
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
-- 26/09/2013 v. 0.1
-----------------------------------------------------------
CREATE OR REPLACE FUNCTION ST_DeleteBand(
    rast raster,
    band int
) 
    RETURNS raster AS 
    $$
    DECLARE
        numband int := ST_NumBands(rast);
        newrast raster := ST_MakeEmptyRaster(rast);
    BEGIN
        FOR b IN 1..numband LOOP
            IF b != band THEN
                newrast := ST_AddBand(newrast, rast, b, NULL);
            END IF;
        END LOOP;
        RETURN newrast;
    END;
    $$
    LANGUAGE 'plpgsql';
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
