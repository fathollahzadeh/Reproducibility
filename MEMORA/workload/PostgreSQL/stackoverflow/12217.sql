
WITH RecentPosts AS (
    SELECT 
        p.PostTypeId,
        p.Score,
        u.Reputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    rp.PostTypeId,
    COUNT(*) AS PostCount,
    AVG(rp.Score) AS AvgScore,
    AVG(rp.Reputation) AS AvgUserReputation
FROM 
    RecentPosts rp
GROUP BY 
    rp.PostTypeId
ORDER BY 
    rp.PostTypeId;
