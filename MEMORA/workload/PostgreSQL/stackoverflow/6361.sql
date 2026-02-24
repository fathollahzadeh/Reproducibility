WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikis,
        SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        LEAD(p.CreationDate) OVER (ORDER BY p.CreationDate) AS NextPostDate,
        EXTRACT(EPOCH FROM (LEAD(p.CreationDate) OVER (ORDER BY p.CreationDate) - p.CreationDate)) AS TimeToNextPost
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.Questions,
        ua.Answers,
        ua.TagWikis,
        ua.ClosedPosts,
        ROW_NUMBER() OVER (ORDER BY ua.TotalPosts DESC) AS Rank
    FROM 
        UserActivity ua
    WHERE 
        ua.TotalPosts > 0
),
RecentPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.Score,
        ps.CreationDate,
        ps.NextPostDate,
        ps.TimeToNextPost,
        u.DisplayName AS OwnerDisplayName
    FROM 
        PostStatistics ps
    JOIN 
        Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)
    WHERE 
        ps.ViewCount > 100
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.TagWikis,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.TimeToNextPost
FROM 
    TopUsers tu
JOIN 
    RecentPosts rp ON tu.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
ORDER BY 
    tu.Rank, rp.CreationDate DESC;