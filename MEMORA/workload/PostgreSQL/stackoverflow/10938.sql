
WITH UserStats AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        UpVotes,
        DownVotes,
        Views,
        (UpVotes - DownVotes) AS NetVotes
    FROM 
        Users
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.CreationDate,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
),
BadgeStats AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    u.UserId,
    u.Reputation,
    u.Views,
    p.PostId,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    b.BadgeCount,
    b.GoldBadges,
    b.SilverBadges,
    b.BronzeBadges,
    p.CreationDate AS PostCreationDate
FROM 
    UserStats u
JOIN 
    PostStats p ON u.UserId = p.OwnerUserId
LEFT JOIN 
    BadgeStats b ON u.UserId = b.UserId
ORDER BY 
    u.Reputation DESC, 
    p.Score DESC
LIMIT 100;
