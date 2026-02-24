
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(NULLIF(rp.CommentCount, 0), 0) AS CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    CASE 
        WHEN rp.Score >= 100 THEN 'High Score'
        WHEN rp.Score >= 50 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS Score_Category,
    CASE 
        WHEN rp.rn = 1 THEN 'Most Recent Post of User'
        ELSE 'Older Post'
    END AS Post_Status
FROM RankedPosts rp
WHERE rp.ViewCount > 50
  AND rp.rn <= 3
ORDER BY rp.Score DESC, rp.ViewCount DESC;
