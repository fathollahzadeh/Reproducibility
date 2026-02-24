WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        (SELECT COUNT(DISTINCT l.RelatedPostId)
         FROM PostLinks l 
         WHERE l.PostId = p.Id) AS RelatedPostCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank,
        (SELECT COUNT(DISTINCT b.Id) 
         FROM Badges b 
         WHERE b.UserId = u.Id AND b.Class = 1) AS GoldBadges
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
PostCloseReasons AS (
    SELECT 
        ph.PostId, 
        STRING_AGG(CASE WHEN ph.PostHistoryTypeId = 10 
                        THEN cr.Name END, ', ') AS CloseReasons
    FROM 
        PostHistory ph 
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CommentCount,
    ur.Reputation,
    ur.ReputationRank,
    ur.GoldBadges,
    pr.CloseReasons,
    CASE 
        WHEN rp.CommentCount > 5 THEN 'Highly Engaged'
        WHEN rp.CommentCount BETWEEN 3 AND 5 THEN 'Moderately Engaged'
        ELSE 'Less Engaged' 
    END AS EngagementLevel,
    CASE 
        WHEN rp.RelatedPostCount = 0 THEN 'No Related Posts'
        ELSE 'Has Related Posts'
    END AS RelatedPostsStatus
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    PostCloseReasons pr ON pr.PostId = rp.PostId
WHERE 
    (ur.Reputation > 1000 OR rp.Score >= 10)
    AND (rp.PostRank <= 3 OR rp.CommentCount > 0)
ORDER BY 
    rp.Score DESC, ur.Reputation DESC;