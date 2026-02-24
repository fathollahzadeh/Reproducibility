WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
        AND p.Score >= 0
        AND p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PostsWithBadge AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        b.Name AS BadgeName,
        b.Date AS BadgeDate
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        b.Class = 1 OR b.Class = 2
),
FinalResults AS (
    SELECT 
        p.Title,
        p.Score,
        u.UserId,
        u.TotalScore,
        u.PostCount,
        u.AvgViewCount,
        COALESCE(pb.BadgeName, 'No Badge') AS BadgeName
    FROM 
        RankedPosts p
    JOIN 
        UserScores u ON p.PostId = u.UserId
    LEFT JOIN 
        PostsWithBadge pb ON p.PostId = pb.PostId
    WHERE 
        p.UserPostRank <= 5
)
SELECT 
    Title,
    Score,
    UserId,
    TotalScore,
    PostCount,
    AvgViewCount,
    BadgeName
FROM 
    FinalResults
ORDER BY 
    TotalScore DESC, Score DESC
LIMIT 50;