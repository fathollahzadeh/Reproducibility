WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
),
PostStats AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        (SELECT COALESCE(AVG(v.BountyAmount), 0)
         FROM Votes v 
         WHERE v.PostId = rp.Id AND v.VoteTypeId IN (8, 9)) AS AvgBounty,
        (SELECT COUNT(*) 
         FROM PostHistory ph 
         WHERE ph.PostId = rp.Id AND ph.PostHistoryTypeId = 10) AS CloseCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RN = 1
)
SELECT 
    ps.Id,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.AvgBounty,
    ps.CloseCount,
    CASE 
        WHEN ps.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN ps.Score < 0 THEN 'Negative'
        WHEN ps.Score > 0 THEN 'Positive'
        ELSE 'Neutral'
    END AS ScoreCategory
FROM 
    PostStats ps
ORDER BY 
    ps.ViewCount DESC,
    ps.Score DESC;
