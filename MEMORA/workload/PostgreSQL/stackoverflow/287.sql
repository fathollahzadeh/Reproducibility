WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY p.Id
), RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        ps.VoteCount,
        CASE 
            WHEN ps.Rank = 1 THEN 'Top Post'
            WHEN ps.Rank <= 5 THEN 'High Performer'
            ELSE 'Regular Post' 
        END AS PostCategory
    FROM PostStats ps
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.VoteCount,
    rp.PostCategory,
    COALESCE(u.DisplayName, 'Anonymous') AS Author,
    COALESCE(SUM(b.Class), 0) AS TotalBadges,
    MAX(ph.CreationDate) AS LastEditDate
FROM RankedPosts rp
LEFT JOIN Users u ON rp.PostId = u.Id
LEFT JOIN Badges b ON u.Id = b.UserId
LEFT JOIN PostHistory ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId IN (4, 5)
GROUP BY 
    rp.PostId, 
    rp.Title, 
    rp.Score, 
    rp.ViewCount, 
    rp.CommentCount, 
    rp.VoteCount, 
    rp.PostCategory, 
    u.DisplayName
HAVING 
    AVG(rp.Score) > 10 
    OR COUNT(DISTINCT ph.Id) > 2
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 50;