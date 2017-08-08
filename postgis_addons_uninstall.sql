-------------------------------------------------------------------------------
-- PostGIS PL/pgSQL Add-ons - Uninstallation file
-- Version 1.35 for PostGIS 2.1.x and PostgreSQL 9.x
-- http://github.com/pedrogit/postgisaddons
--
-- This is free software; you can redistribute and/or modify it under
-- the terms of the GNU General Public Licence. See the COPYING file.
--
-- Copyright (C) 2013-2017 Pierre Racine <pierre.racine@sbf.ulaval.ca>


DROP FUNCTION IF EXISTS ST_DeleteBand(raster, int);

DROP FUNCTION IF EXISTS ST_CreateIndexRaster(raster, text, int, boolean, boolean, boolean, boolean, int, int);

DROP FUNCTION IF EXISTS ST_RandomPoints(geometry, integer, numeric);

DROP FUNCTION IF EXISTS ST_ColumnExists(name, name, name);
DROP FUNCTION IF EXISTS ST_ColumnExists(name, name);

DROP FUNCTION IF EXISTS ST_AddUniqueID(name, name, name, boolean, boolean);
DROP FUNCTION IF EXISTS ST_AddUniqueID(name, name, boolean, boolean);

DROP AGGREGATE IF EXISTS ST_AreaWeightedSummaryStats(geomval);
DROP AGGREGATE IF EXISTS ST_AreaWeightedSummaryStats(geometry, double precision);
DROP AGGREGATE IF EXISTS ST_AreaWeightedSummaryStats(geometry);
DROP FUNCTION IF EXISTS _ST_AreaWeightedSummaryStats_FinalFN(agg_areaweightedstatsstate);
DROP FUNCTION IF EXISTS _ST_AreaWeightedSummaryStats_StateFN(agg_areaweightedstatsstate, geometry);
DROP FUNCTION IF EXISTS _ST_AreaWeightedSummaryStats_StateFN(agg_areaweightedstatsstate, geometry, double precision);
DROP FUNCTION IF EXISTS _ST_AreaWeightedSummaryStats_StateFN(agg_areaweightedstatsstate, geomval);
DROP TYPE IF EXISTS agg_areaweightedstats;
DROP TYPE IF EXISTS agg_areaweightedstatsstate;

DROP FUNCTION IF EXISTS ST_ExtractPixelCentroidValue4ma(double precision[][][], int[][], text[]);
DROP FUNCTION IF EXISTS ST_ExtractPixelValue4ma(double precision[][][], int[][], text[]);
DROP FUNCTION IF EXISTS ST_ExtractToRaster(raster, integer, name, name, name, name, text);
DROP FUNCTION IF EXISTS ST_ExtractToRaster(raster, name, name, name, name, text);
DROP FUNCTION IF EXISTS ST_ExtractToRaster(raster, integer, name, name, name, text);
DROP FUNCTION IF EXISTS ST_ExtractToRaster(raster, name, name, name, text);

DROP FUNCTION IF EXISTS ST_GlobalRasterUnion(name, name, name, text, text, double precision);

DROP AGGREGATE IF EXISTS ST_BufferedUnion(geometry, double precision);
DROP FUNCTION IF EXISTS _ST_BufferedUnion_StateFN(geomval, geometry, double precision);
DROP FUNCTION IF EXISTS _ST_BufferedUnion_FinalFN(geomval);

DROP FUNCTION IF EXISTS ST_NBiggestExteriorRings(geometry, integer, text);

DROP FUNCTION IF EXISTS ST_BufferedSmooth(geometry, double precision);

DROP AGGREGATE IF EXISTS ST_DifferenceAgg(geometry, geometry);
DROP FUNCTION IF EXISTS _ST_DifferenceAgg_StateFN(geomval, geometry, geometry);
DROP FUNCTION IF EXISTS _ST_DifferenceAgg_FinalFN(geomval);

DROP FUNCTION IF EXISTS ST_TrimMulti(geometry, double precision);

DROP AGGREGATE IF EXISTS ST_SplitAgg(geometry, geometry, double precision);
DROP AGGREGATE IF EXISTS ST_SplitAgg(geometry, geometry);
DROP FUNCTION IF EXISTS _ST_SplitAgg_StateFN(geometry[], geometry, geometry);
DROP FUNCTION IF EXISTS _ST_SplitAgg_StateFN(geometry[], geometry, geometry, double precision);

DROP FUNCTION IF EXISTS ST_HasBasicIndex(name, name, name);
DROP FUNCTION IF EXISTS ST_HasBasicIndex(name, name);

DROP FUNCTION IF EXISTS ST_ColumnIsUnique(name, name, name);
DROP FUNCTION IF EXISTS ST_ColumnIsUnique(name, name);

DROP FUNCTION IF EXISTS ST_GeoTableSummary(name, name, name, name, int, text[], text[], text);
DROP FUNCTION IF EXISTS ST_GeoTableSummary(name, name, name, name, int, text, text, text);

DROP FUNCTION IF EXISTS ST_SplitByGrid(geometry, double precision, double precision, double precision, double precision);

DROP FUNCTION IF EXISTS ST_Histogram(text, text, text, int, text);

