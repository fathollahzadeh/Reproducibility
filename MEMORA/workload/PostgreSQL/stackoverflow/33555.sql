
WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        CAST(u.Reputation AS BIGINT) AS AccumulatedReputation,
        0 AS Level
    FROM 
        Users u
    WHERE 
        u.Reputation > 0

    UNION ALL

    SELECT 
        u.Id, 
        u.Reputation,
        ur.AccumulatedReputation + u.Reputation,
        Level + 1
    FROM 
        Users u
    INNER JOIN 
        UserReputationCTE ur ON u.Id = ur.UserId
    WHERE 
        Level < 3
)

SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(ur.AccumulatedReputation, 0) AS TotalReputation,
    COUNT(p.Id) AS PostCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    CASE 
        WHEN COUNT(p.Id) > 0 THEN 
            ROUND(SUM(p.Score) / COUNT(p.Id), 2)
        ELSE 
            0
    END AS AveragePostScore,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(p.Tags, ',')) AS TagName
    ) t ON TRUE
LEFT JOIN 
    UserReputationCTE ur ON u.Id = ur.UserId
WHERE 
    u.Reputation > 100
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, ur.AccumulatedReputation
ORDER BY 
    TotalReputation DESC
LIMIT 10;
