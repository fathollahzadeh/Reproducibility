WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' AND
        p.Score > 0
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT bp.PostId) AS TotalPosts,
        SUM(bp.Score) AS TotalScore,
        SUM(bp.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        RankedPosts bp ON u.Id = bp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.TotalScore,
        us.TotalViews,
        RANK() OVER (ORDER BY us.TotalScore DESC) AS ScoreRank
    FROM 
        UserStatistics us
)
SELECT 
    t.DisplayName,
    t.TotalPosts,
    t.TotalScore,
    t.TotalViews,
    pt.Name AS PostType
FROM 
    TopUsers t
JOIN 
    Posts p ON p.OwnerUserId = t.UserId
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    t.ScoreRank <= 10
ORDER BY 
    t.TotalScore DESC, t.TotalPosts DESC;