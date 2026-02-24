WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
),
LatestPostStats AS (
    SELECT 
        p.OwnerUserId,
        MAX(p.ViewCount) AS MaxViewCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalQuestions,
        us.TotalScore,
        us.AverageScore,
        lps.MaxViewCount,
        lps.CommentCount,
        ROW_NUMBER() OVER (ORDER BY us.TotalScore DESC) AS UserRank
    FROM 
        UserStatistics us
    JOIN 
        LatestPostStats lps ON us.UserId = lps.OwnerUserId
)
SELECT 
    cu.DisplayName AS TopUser,
    cu.TotalQuestions,
    cu.TotalScore,
    cu.AverageScore,
    cu.MaxViewCount,
    cu.CommentCount,
    COUNT(DISTINCT ph.Id) AS TotalPostHistoryActions,
    STRING_AGG(DISTINCT pht.Name, ', ') AS RecentPostHistoryTypeNames
FROM 
    TopUsers cu
LEFT JOIN 
    Posts p ON cu.UserId = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    cu.UserRank <= 10 
GROUP BY 
    cu.UserId, cu.DisplayName, cu.TotalQuestions, cu.TotalScore, cu.AverageScore, cu.MaxViewCount, cu.CommentCount
ORDER BY 
    cu.TotalScore DESC;