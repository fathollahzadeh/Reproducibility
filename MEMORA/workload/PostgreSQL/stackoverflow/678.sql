WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        MIN(p.CreationDate) AS FirstPostDate,
        RANK() OVER (PARTITION BY u.Id ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS ScoreRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), 
HighScorers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        TotalScore, 
        FirstPostDate
    FROM 
        UserActivity
    WHERE 
        ScoreRank <= 10
), 
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    hs.DisplayName,
    hs.PostCount,
    hs.TotalScore,
    hs.FirstPostDate,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score
FROM 
    HighScorers hs
LEFT JOIN 
    RecentPosts rp ON hs.UserId = rp.OwnerUserId AND rp.RecentRank <= 5
ORDER BY 
    hs.TotalScore DESC, hs.DisplayName;