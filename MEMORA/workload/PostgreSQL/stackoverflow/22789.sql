
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE((
            SELECT COUNT(*) 
            FROM Votes v 
            WHERE v.PostId = p.Id AND v.VoteTypeId = 2
        ), 0) AS UpVotesCount
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '2 years'
), 
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.UpVotesCount,
        CASE 
            WHEN rp.Score > 100 THEN 'Hot Topic'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Popular'
            ELSE 'Normal'
        END AS Popularity
    FROM RankedPosts rp
    WHERE rp.Rank <= 10
), 
PostMetrics AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.ViewCount,
        pp.UpVotesCount,
        pp.Popularity,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT h.Id) AS HistoryEditCount,
        MAX(h.CreationDate) AS LastEditDate
    FROM PopularPosts pp
    LEFT JOIN Comments c ON pp.PostId = c.PostId
    LEFT JOIN PostHistory h ON pp.PostId = h.PostId AND h.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY pp.PostId, pp.Title, pp.ViewCount, pp.UpVotesCount, pp.Popularity
)
SELECT 
    pm.Title,
    pm.ViewCount,
    pm.UpVotesCount,
    pm.Popularity,
    pm.CommentCount,
    pm.LastEditDate,
    CASE 
        WHEN pm.Popularity = 'Hot Topic' AND pm.CommentCount > 50 THEN 'Featured Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM PostMetrics pm
WHERE pm.UpVotesCount > 10
AND (pm.CommentCount IS NULL OR pm.CommentCount < 20)
ORDER BY pm.ViewCount DESC;
