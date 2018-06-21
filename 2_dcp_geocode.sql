-- Upload nyzma (May 2018 version used)
-- Upload imPACT Visualization polygons (April 2018 version used, frozen to ZAP go-live date)
-- Upload project actions

/**Add project_id to nyzma**/
-- *Note that this step is required because nyzma only tracks a project by lead ulurp number (assumed it's lead ulurp number). However, ZAP project data only tracks projects by project ID. ZAP project actions tables is the only dataset that links project ID to each ulurp number associated with the project
-- *Note again that this must be done borough-by-borough due to limitations with exporting data with 5000+ records from ZAP

ALTER TABLE capitalplanning.nyzma_may2018
ADD COLUMN project_id text,
ADD COLUMN project_action_status text;

WITH temp AS (
SELECT
  z.ulurpno AS ulurp,
  a.project AS project,
  a.project_action_status AS status
FROM 
  capitalplanning.nyzma_may2018 AS z,
  capitalplanning.bx_actions AS a
WHERE z.ulurpno = lower(right(a.ulurp_number,char_length(a.ulurp_number)-1)))

UPDATE capitalplanning.nyzma_may2018
SET project_id = temp.project, project_action_status = temp.status
FROM temp
WHERE ulurpno = temp.ulurp

/**Repeat above for other boroughs**/
