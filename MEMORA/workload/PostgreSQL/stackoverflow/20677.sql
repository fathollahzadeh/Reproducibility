WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 month' 
        AND p.Score IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id 
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
    GROUP BY 
        u.Id, u.Reputation
),
HighScoringPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        ur.Reputation,
        ur.TotalBadges,
        ur.TotalPosts,
        RANK() OVER (ORDER BY rp.Score DESC) AS HighScoreRank
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    WHERE 
        COALESCE(rp.Score, 0) > 100
),
LowScorePosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        ur.Reputation,
        ur.TotalBadges,
        ur.TotalPosts,
        RANK() OVER (ORDER BY rp.Score ASC) AS LowScoreRank
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    WHERE 
        COALESCE(rp.Score, 0) < 0
),
FinalResults AS (
    SELECT 
        p.Title,
        p.Score,
        ur.Reputation,
        ur.TotalBadges,
        'High' AS PostType
    FROM 
        HighScoringPosts p
    JOIN 
        UserReputation ur ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = p.PostId)

    UNION ALL

    SELECT 
        p.Title,
        p.Score,
        ur.Reputation,
        ur.TotalBadges,
        'Low' AS PostType
    FROM 
        LowScorePosts p
    JOIN 
        UserReputation ur ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = p.PostId)
)
SELECT 
    Title, 
    Score, 
    Reputation, 
    TotalBadges, 
    COUNT(*) OVER (PARTITION BY PostType) AS CountByType, 
    CASE 
        WHEN Reputation > 1000 THEN 'Veteran'
        WHEN Reputation BETWEEN 500 AND 1000 THEN 'Experienced'
        ELSE 'Novice'
    END AS UserType
FROM 
    FinalResults
WHERE 
    (PostType = 'High' AND Score > 200) 
    OR (PostType = 'Low' AND Score < -10)
ORDER BY 
    UserType, 
    Score DESC;