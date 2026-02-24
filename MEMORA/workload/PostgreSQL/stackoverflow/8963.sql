
WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY BadgeCount DESC) AS BadgeRank
    FROM UserBadgeCounts
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS PopularityRank
    FROM Posts p
    WHERE p.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
),
UserPostInteractions AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
)

SELECT 
    u.DisplayName,
    u.Reputation,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    p.PostId,
    p.Title AS PopularPostTitle,
    p.ViewCount,
    up.PostCount,
    up.Upvotes AS TotalUpvotes,
    up.Downvotes AS TotalDownvotes
FROM Users u
JOIN UserBadgeCounts ub ON u.Id = ub.UserId
JOIN UserPostInteractions up ON u.Id = up.UserId
JOIN PopularPosts p ON up.PostCount > 0
WHERE ub.BadgeCount > 0
ORDER BY ub.BadgeCount DESC, p.ViewCount DESC
LIMIT 10;
