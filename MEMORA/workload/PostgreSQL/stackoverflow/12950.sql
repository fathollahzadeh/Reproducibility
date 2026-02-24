
WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        COUNT(DISTINCT CASE WHEN b.Id IS NOT NULL THEN b.Id END) AS BadgeCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PostHistorySummary AS (
    SELECT 
        PostId,
        COUNT(*) AS HistoryActionCount,
        MAX(CreationDate) AS LastActivityDate
    FROM 
        PostHistory
    GROUP BY 
        PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate AS PostCreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    ps.BadgeCount,
    ps.Tags,
    phs.HistoryActionCount,
    phs.LastActivityDate
FROM 
    PostSummary ps
LEFT JOIN 
    PostHistorySummary phs ON ps.PostId = phs.PostId
ORDER BY 
    ps.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
