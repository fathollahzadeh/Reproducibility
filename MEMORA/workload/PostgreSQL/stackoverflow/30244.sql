
WITH RECURSIVE UserReputation AS (
    SELECT 
        u.Id,
        u.Reputation,
        u.DisplayName,
        1 AS Level
    FROM 
        Users u
    WHERE 
        u.Reputation > 500  
    UNION ALL
    SELECT 
        u.Id,
        u.Reputation,
        u.DisplayName,
        ur.Level + 1
    FROM 
        Users u
    INNER JOIN 
        UserReputation ur ON ur.Id = u.Id  
    WHERE 
        u.Reputation > 500 * ur.Level
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        MAX(p.Score) AS MaxScore,
        AVG(p.Score) AS AvgScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    WHERE 
        p.CreationDate >= '2023-01-01'  
    GROUP BY 
        p.Id
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    ur.DisplayName,
    p.Title,
    ps.MaxScore,
    ps.AvgScore,
    phd.EditCount,
    phd.FirstEditDate,
    phd.LastEditDate
FROM 
    UserReputation ur
JOIN 
    Posts p ON ur.Id = p.OwnerUserId
JOIN 
    PostStats ps ON p.Id = ps.PostId
LEFT JOIN 
    PostHistoryData phd ON p.Id = phd.PostId
WHERE 
    ps.AvgScore IS NOT NULL
    AND phd.FirstEditDate IS NOT NULL
ORDER BY 
    ps.AvgScore DESC,
    phd.EditCount DESC
LIMIT 10;
