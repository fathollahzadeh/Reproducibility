
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '90 days'
        AND p.PostTypeId IN (1, 2)
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        AnswerCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank = 1
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    u.DisplayName AS UserName,
    u.TotalPosts,
    u.PositivePosts,
    u.NegativePosts,
    t.PostId,
    t.Title,
    t.Score AS TopScore,
    t.ViewCount,
    t.AnswerCount
FROM 
    UserActivity u
JOIN 
    TopRankedPosts t ON u.TotalPosts > 0
ORDER BY 
    u.TotalPosts DESC, 
    t.Score DESC
LIMIT 10;
