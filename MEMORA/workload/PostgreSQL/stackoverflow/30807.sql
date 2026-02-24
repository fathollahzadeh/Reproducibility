
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND
        p.AnswerCount > 0  
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(vb.BountyAmount), 0) AS TotalBounty,
        MAX(pa.CreationDate) AS LastActiveDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes vb ON p.Id = vb.PostId AND vb.VoteTypeId = 8  
    LEFT JOIN 
        Posts pa ON u.Id = pa.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.TotalBounty,
        ua.LastActiveDate,
        CASE 
            WHEN ua.PostCount > 10 THEN 'High Activity'
            WHEN ua.PostCount BETWEEN 5 AND 10 THEN 'Medium Activity'
            ELSE 'Low Activity'
        END AS ActivityLevel
    FROM 
        UserActivity ua
    WHERE 
        ua.LastActiveDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserId,
    up.DisplayName,
    a.PostId,
    a.Title,
    a.CreationDate,
    a.Score,
    a.ViewCount,
    ph.EditCount,
    ph.LastEditDate,
    up.TotalBounty,
    up.ActivityLevel
FROM 
    ActiveUsers up
JOIN 
    RankedPosts a ON up.UserId = a.PostId 
JOIN 
    PostHistorySummary ph ON a.PostId = ph.PostId 
WHERE 
    a.ScoreRank = 1  
ORDER BY 
    up.ActivityLevel DESC, a.Score DESC
LIMIT 50;
