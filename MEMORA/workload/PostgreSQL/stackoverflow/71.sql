
WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, u.DisplayName
), RankedPosts AS (
    SELECT 
        Id,
        Title,
        ViewCount,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        UpvoteCount,
        DownvoteCount,
        ROW_NUMBER() OVER (ORDER BY UpvoteCount DESC, CommentCount DESC) AS Rank
    FROM 
        RecentPosts
)
SELECT 
    r.Id,
    r.Title,
    r.ViewCount,
    r.CreationDate,
    r.OwnerDisplayName,
    r.CommentCount,
    r.UpvoteCount,
    r.DownvoteCount,
    CASE 
        WHEN r.UpvoteCount - r.DownvoteCount > 0 THEN 'Positive'
        WHEN r.UpvoteCount - r.DownvoteCount < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    COALESCE(ph.Comment, 'No recent changes') AS RecentChange
FROM 
    RankedPosts r
LEFT JOIN 
    PostHistory ph ON r.Id = ph.PostId AND ph.CreationDate = (
        SELECT MAX(CreationDate) 
        FROM PostHistory 
        WHERE PostId = r.Id
    )
WHERE 
    r.Rank <= 10
ORDER BY 
    r.Rank;
