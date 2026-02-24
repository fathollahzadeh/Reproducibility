WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
        AND p.ViewCount > 0
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.LastActivityDate, p.OwnerUserId, u.DisplayName
),
TopUserPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.ViewCount,
        r.OwnerDisplayName,
        r.CommentCount,
        r.UpvoteCount,
        r.DownvoteCount,
        r.Rank
    FROM
        RankedPosts r
    WHERE
        r.Rank <= 5
)
SELECT 
    t.OwnerDisplayName,
    COUNT(t.PostId) AS TotalPosts,
    SUM(t.ViewCount) AS TotalViews,
    SUM(t.UpvoteCount) AS TotalUpvotes,
    SUM(t.DownvoteCount) AS TotalDownvotes,
    AVG(t.CommentCount) AS AvgCommentsPerPost
FROM 
    TopUserPosts t
GROUP BY 
    t.OwnerDisplayName
ORDER BY 
    TotalViews DESC
LIMIT 10;