/**Develop match method**/
-- *Note that matched by DCP project ID since all EDC projects shared were also in DCP

SELECT
    i.project_id, i.project_name, project_completed, certified_referred, units,
    e.edc_id, e.project_name AS edc_project_name, e.total_units AS edc_total_units, e.incremental_edc_units
FROM
	capitalplanning.all_possible_projects AS i,
    capitalplanning.edc_2018_sca_input AS e
WHERE e.dcp_project_id = i.project_id

-- Create new dataset from query as dcp_edc_dedupe
