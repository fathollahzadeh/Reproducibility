WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    us.TotalScore,
    COALESCE(rp.Title, 'No Posts') AS TopPostTitle,
    COALESCE(rp.Score, 0) AS TopPostScore,
    us.QuestionCount,
    CASE 
        WHEN us.TotalScore IS NULL THEN 'No Score'
        WHEN us.TotalScore > 500 THEN 'High Impact User'
        ELSE 'User Needs Engagement'
    END AS UserStatus
FROM 
    Users u
JOIN 
    UserScores us ON u.Id = us.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.Rank
WHERE 
    u.Location IS NULL 
    OR u.Location LIKE '%USA%' 
ORDER BY 
    us.TotalScore DESC, 
    u.Reputation DESC
LIMIT 100;