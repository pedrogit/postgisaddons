-------------------------------------------------------------------------------
-- PostGIS PL/pgSQL Add-ons - Uninstall ST_SummaryStatsAgg()
-- Version 1.35 for PostGIS 2.1.x and PostgreSQL 9.x
-- http://github.com/pedrogit/postgisaddons
--
-- This is free software; you can redistribute and/or modify it under
-- the terms of the GNU General Public Licence. See the COPYING file.
--
-- Copyright (C) 2013-2017 Pierre Racine <pierre.racine@sbf.ulaval.ca>
-- 
-------------------------------------------------------------------------------
DROP AGGREGATE IF EXISTS ST_SummaryStatsAgg(raster, int, boolean, double precision);
DROP AGGREGATE IF EXISTS ST_SummaryStatsAgg(raster);
DROP FUNCTION IF EXISTS _ST_SummaryStatsAgg_StateFN(agg_summarystats, raster, int, boolean, double precision);
DROP FUNCTION IF EXISTS _ST_SummaryStatsAgg_StateFN(agg_summarystats, raster);
DROP FUNCTION IF EXISTS _ST_SummaryStatsAgg_FinalFN(agg_summarystats);
DROP TYPE IF EXISTS agg_summarystats;
