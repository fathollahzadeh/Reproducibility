
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(p.Id) DESC) AS ActivityRank
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(ph.HistoryCount, 0) AS HistoryCount
    FROM 
        Posts p
        LEFT JOIN (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
        LEFT JOIN (SELECT PostId, COUNT(*) AS HistoryCount FROM PostHistory GROUP BY PostId) ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
TopViewedPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        CommentCount, 
        HistoryCount,
        RANK() OVER (ORDER BY ViewCount DESC) AS ViewRank
    FROM 
        PostDetails
)
SELECT 
    ua.DisplayName,
    ua.PostCount,
    ua.Upvotes,
    ua.Downvotes,
    ua.AvgScore,
    tp.Title,
    tp.ViewCount,
    tp.CommentCount,
    tp.HistoryCount
FROM 
    UserActivity ua
    JOIN TopViewedPosts tp ON ua.UserId = tp.PostId 
WHERE 
    ua.ActivityRank <= 10
    AND tp.ViewRank <= 50
ORDER BY 
    ua.Upvotes DESC, tp.ViewCount DESC;
