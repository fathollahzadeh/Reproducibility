
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COALESCE(MAX(b.Class), 0) AS BadgeClass
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE
        p.CreationDate BETWEEN TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND TIMESTAMP '2024-10-01 12:34:56'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
PostHistoryAssessments AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT ph.Comment, ', ') AS CloseReasons,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseOpenCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.Upvotes,
    rp.Downvotes,
    pha.CloseReasons,
    pha.CloseOpenCount,
    CASE 
        WHEN rp.ScoreRank = 1 THEN 'Top Post of its Type'
        WHEN rp.ScoreRank <= 5 THEN 'Highly Rated Post'
        ELSE 'Regular Post'
    END AS PostTier,
    CASE 
        WHEN rp.BadgeClass > 1 THEN 'User has Silver or Gold Badge'
        ELSE 'No high-level badge'
    END AS UserBadgeStatus,
    CASE 
        WHEN rp.Upvotes IS NULL AND rp.Downvotes IS NULL THEN 'No votes yet'
        ELSE 'Votes recorded'
    END AS VoteStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryAssessments pha ON rp.PostId = pha.PostId
WHERE 
    (rp.Score > 0 OR rp.CommentCount > 0) 
    AND rp.ViewCount > COALESCE((SELECT AVG(ViewCount) FROM Posts), 0)
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 50 OFFSET 0;
