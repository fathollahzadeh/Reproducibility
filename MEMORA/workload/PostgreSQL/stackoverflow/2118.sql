
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND
        u.Reputation > 1000
), 
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1
    GROUP BY 
        b.UserId
), 
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    COALESCE(ub.BadgeCount, 0) AS GoldBadgeCount,
    COALESCE(pc.CommentCount, 0) AS Comments,
    rp.ViewCount,
    rp.Score,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'No Views'
        ELSE CAST(rp.ViewCount AS CHAR)
    END AS ViewCountText,
    CASE 
        WHEN rp.AnswerCount > 0 THEN 'Has Answers'
        ELSE 'No Answers'
    END AS AnswerStatus,
    CASE 
        WHEN rp.Score > 0 THEN 'Positive Score'
        WHEN rp.Score < 0 THEN 'Negative Score'
        ELSE 'Neutral Score'
    END AS ScoreStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.UserRank = 1
ORDER BY 
    rp.CreationDate DESC
FETCH FIRST 50 ROWS ONLY;
