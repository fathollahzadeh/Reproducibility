WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        0 AS Depth,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 

    UNION ALL

    SELECT 
        p2.Id AS PostId,
        p2.ParentId,
        ph.Depth + 1,
        p2.Title,
        p2.CreationDate,
        p2.ViewCount,
        p2.Score,
        p2.OwnerUserId
    FROM 
        Posts p2
    INNER JOIN 
        PostHierarchy ph ON p2.ParentId = ph.PostId
)
, UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        AVG(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS AverageViewCount,
        COUNT(b.Name) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
),
CloseVoteCounts AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS CloseVotes
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    us.QuestionCount,
    us.TotalScore,
    us.AverageViewCount,
    COALESCE(cvc.CloseVotes, 0) AS CloseVotes,
    COUNT(DISTINCT ph.PostId) AS SubquestionCount,
    STRING_AGG(DISTINCT p.Tags, ', ') AS Tags
FROM 
    Users u
JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    CloseVoteCounts cvc ON u.Id = cvc.UserId
LEFT JOIN 
    PostHierarchy ph ON u.Id = ph.OwnerUserId
LEFT JOIN 
    Posts p ON p.Id = ph.PostId
WHERE 
    u.Reputation >= 1000
    AND us.QuestionCount > 5
GROUP BY 
    u.Id, u.DisplayName, us.QuestionCount, us.TotalScore, us.AverageViewCount, cvc.CloseVotes
HAVING 
    COUNT(DISTINCT ph.PostId) > 10
ORDER BY 
    us.TotalScore DESC, us.QuestionCount DESC;