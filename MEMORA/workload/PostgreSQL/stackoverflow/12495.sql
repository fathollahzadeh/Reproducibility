WITH PostCounts AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS UniqueUsers,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS PositiveScores,
        SUM(CASE WHEN AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN p.Id IS NOT NULL THEN 1 ELSE 0 END) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.Reputation
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    ORDER BY 
        p.Score DESC
    LIMIT 10
)
SELECT 
    pc.PostTypeId,
    pc.TotalPosts,
    pc.UniqueUsers,
    pc.PositiveScores,
    pc.AcceptedAnswers,
    us.Reputation,
    us.BadgeCount,
    us.PostCount,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerName
FROM 
    PostCounts pc
JOIN 
    UserStatistics us ON us.PostCount > 0
CROSS JOIN 
    TopPosts tp;