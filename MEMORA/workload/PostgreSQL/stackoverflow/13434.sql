
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS AuthorName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COALESCE(MAX(b.Date), DATE '1900-01-01') AS LastBadgeDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AuthorName,
    rp.CommentCount,
    rp.VoteCount,
    rp.LastBadgeDate,
    (SELECT COUNT(*) FROM Comments WHERE PostId = rp.PostId) AS TotalComments,
    (SELECT AVG(Score) FROM Posts WHERE OwnerUserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)) AS AvgUserScore
FROM 
    RecentPosts rp
ORDER BY 
    rp.ViewCount DESC
LIMIT 50;
