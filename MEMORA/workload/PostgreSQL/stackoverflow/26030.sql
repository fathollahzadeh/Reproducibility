WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 
    ORDER BY p.Score DESC
    LIMIT 50
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    ur.Reputation,
    ur.ReputationRank,
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.Tags,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    tp.AnswerCount,
    tp.ViewCount,
    tp.CommentCount,
    ub.BadgeCount,
    ub.BadgeNames
FROM UserReputation ur
JOIN TopPosts tp ON ur.UserId = tp.OwnerUserId
LEFT JOIN UserBadges ub ON ub.UserId = ur.UserId
ORDER BY ur.Reputation DESC, tp.Score DESC;