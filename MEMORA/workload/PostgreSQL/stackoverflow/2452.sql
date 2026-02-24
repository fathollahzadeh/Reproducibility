
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.PostTypeId = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
PostComments AS (
    SELECT 
        cm.PostId,
        COUNT(*) AS CommentCount
    FROM Comments cm
    GROUP BY cm.PostId
),
PostLinks AS (
    SELECT 
        pl.PostId,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
    FROM PostLinks pl
    GROUP BY pl.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    u.DisplayName,
    u.Reputation,
    ur.TotalBadges,
    rp.CreationDate,
    rp.Score,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(pl.RelatedPostsCount, 0) AS RelatedPostsCount
FROM RankedPosts rp
JOIN Users u ON rp.OwnerUserId = u.Id
JOIN UserReputation ur ON ur.UserId = rp.OwnerUserId
LEFT JOIN PostComments pc ON pc.PostId = rp.PostId
LEFT JOIN PostLinks pl ON pl.PostId = rp.PostId
WHERE rp.rn = 1
  AND ur.Reputation > 100
  AND (rp.Score > 5 OR COALESCE(pl.RelatedPostsCount, 0) > 0)
ORDER BY rp.Score DESC, rp.CreationDate DESC;
