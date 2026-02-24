WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),

PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(pc.PostCount, 0) AS UserPostCount
    FROM 
        Posts p
    LEFT JOIN 
        UserPostCounts pc ON p.OwnerUserId = pc.UserId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.UserPostCount
FROM 
    PostStatistics ps
WHERE 
    ps.Score > 10
ORDER BY 
    ps.ViewCount DESC
LIMIT 100;