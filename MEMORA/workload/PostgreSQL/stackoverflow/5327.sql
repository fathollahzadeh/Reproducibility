
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId IN (1, 2)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        p.OwnerUserId
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    WHERE 
        rp.UserPostRank = 1
),
PostStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(bp.PostId) AS TotalBestPosts,
        SUM(bp.ViewCount) AS TotalViews,
        AVG(bp.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        TopRankedPosts bp ON u.Id = bp.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    u.DisplayName,
    u.Reputation,
    s.TotalBestPosts,
    s.TotalViews,
    s.AverageScore,
    CASE 
        WHEN s.TotalBestPosts > 10 THEN 'Expert'
        WHEN s.TotalBestPosts BETWEEN 5 AND 10 THEN 'Intermediate'
        ELSE 'Beginner'
    END AS UserLevel
FROM 
    Users u
JOIN 
    PostStats s ON u.Id = s.UserId
ORDER BY 
    s.AverageScore DESC, s.TotalViews DESC;
