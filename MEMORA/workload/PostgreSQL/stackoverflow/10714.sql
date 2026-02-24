
WITH PostScore AS (
    SELECT 
        p.Id AS PostId,
        p.Score AS PostScore,
        COUNT(c.Id) AS CommentCount,
        u.Reputation AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'  
    GROUP BY 
        p.Id, p.Score, u.Reputation
),
AverageStats AS (
    SELECT 
        AVG(PostScore) AS AvgPostScore,
        SUM(CommentCount) AS TotalComments,
        AVG(UserReputation) AS AvgUserReputation
    FROM 
        PostScore
)

SELECT 
    * 
FROM 
    AverageStats;
