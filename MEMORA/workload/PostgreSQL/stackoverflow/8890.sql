WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000 AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount 
    FROM 
        Badges b 
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
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        ub.BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.PostId = (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ub.UserId LIMIT 1)
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    WHERE 
        rp.rn <= 5
)
SELECT 
    *,
    (ViewCount + Score + AnswerCount + CommentCount + BadgeCount) AS EngagementScore
FROM 
    FinalResults
ORDER BY 
    EngagementScore DESC;