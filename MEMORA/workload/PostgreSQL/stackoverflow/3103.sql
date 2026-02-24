WITH RecentActivities AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        ra.*,
        (Upvotes - Downvotes) AS Score,
        RANK() OVER (ORDER BY (Upvotes - Downvotes) DESC, ViewCount DESC) AS Rank
    FROM 
        RecentActivities ra
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.CommentCount,
    fp.OwnerName,
    fp.Upvotes,
    fp.Downvotes,
    fp.Score,
    CASE 
        WHEN fp.Score > 0 THEN 'Positive'
        WHEN fp.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreType
FROM 
    FilteredPosts fp
WHERE 
    fp.rn = 1 
    AND fp.Score > 0
ORDER BY 
    fp.Rank
LIMIT 10;