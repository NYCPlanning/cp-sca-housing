/**Identify which projects are rezonings (ZM)**/

SELECT project, count(action_code) AS num_valid_actions, count(CASE WHEN action_code = 'ZM' THEN 1 END) AS zm_action
FROM capitalplanning.bx_actions
WHERE project IN (SELECT DISTINCT project_id FROM capitalplanning.all_possible_projects)
AND project_action_status IN ('Active','Certified','Referred','Approved')
GROUP BY project
ORDER BY project

-- Repeat for all 5 boroughs
