
WITH PostMetrics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        AVG(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE NULL END) AS AvgQuestionScore,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate BETWEEN '2022-01-01' AND '2022-12-31' 
    GROUP BY 
        p.OwnerUserId
)

SELECT 
    u.DisplayName, 
    pm.PostCount, 
    pm.AvgQuestionScore, 
    pm.TotalComments
FROM 
    PostMetrics pm
JOIN 
    Users u ON u.Id = pm.OwnerUserId
ORDER BY 
    pm.PostCount DESC;
