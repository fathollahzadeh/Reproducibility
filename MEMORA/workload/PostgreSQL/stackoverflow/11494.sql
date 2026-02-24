
WITH PostSummary AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)

SELECT
    ps.PostTypeId,
    ps.PostCount,
    ps.AvgScore,
    ur.AvgReputation
FROM 
    PostSummary ps
JOIN 
    UserReputation ur ON ur.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE PostTypeId = ps.PostTypeId)
ORDER BY 
    ps.PostCount DESC;
