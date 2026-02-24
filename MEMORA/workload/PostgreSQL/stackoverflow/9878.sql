
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        u.CreationDate,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AverageUpVotes,
        AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS AverageDownVotes,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.UserId, 
        u.DisplayName,
        COUNT(DISTINCT rp.PostId) AS RecentPostCount,
        SUM(rp.ViewCount) AS TotalViewCount,
        SUM(rp.CommentCount) AS TotalCommentCount,
        SUM(rp.AverageUpVotes * rp.ViewCount) AS WeightedUpVotes,
        SUM(rp.AverageDownVotes * rp.ViewCount) AS WeightedDownVotes
    FROM 
        UserReputation u
    JOIN 
        RecentPosts rp ON u.UserId = rp.OwnerUserId
    GROUP BY 
        u.UserId, u.DisplayName
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.RecentPostCount,
    ua.TotalViewCount,
    ua.TotalCommentCount,
    ur.Reputation,
    ur.BadgeCount,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    ua.WeightedUpVotes,
    ua.WeightedDownVotes
FROM 
    UserActivity ua
JOIN 
    UserReputation ur ON ua.UserId = ur.UserId
ORDER BY 
    ua.TotalViewCount DESC, 
    ur.Reputation DESC
LIMIT 50;
