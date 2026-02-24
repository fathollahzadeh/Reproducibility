
WITH RankedUsers AS (
    SELECT 
        u.Id, 
        u.DisplayName, 
        u.Reputation, 
        u.Views,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.Views
),

ActivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        MAX(CASE WHEN Ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN PostHistory Ph ON p.Id = Ph.PostId
    LEFT JOIN LATERAL (
        SELECT UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS TagName
    ) t ON TRUE
    GROUP BY p.Id, p.Title, p.Score, p.AnswerCount, p.CommentCount, p.CreationDate, p.ViewCount, p.OwnerUserId
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
)

SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.Views,
    ru.BadgeCount,
    ru.GoldBadges,
    ru.SilverBadges,
    ru.BronzeBadges,
    COUNT(DISTINCT ap.Id) AS TotalActivePosts,
    SUM(CASE WHEN ap.IsClosed = 1 THEN 1 ELSE 0 END) AS ClosedPosts,
    SUM(ua.TotalPosts) AS PostsCreated,
    SUM(ua.TotalBounty) AS TotalBountyReward,
    SUM(ua.UpVotes) AS TotalUpVotes,
    SUM(ua.DownVotes) AS TotalDownVotes,
    STRING_AGG(DISTINCT ap.Tags, '; ') AS AllPostTags
FROM RankedUsers ru
JOIN ActivePosts ap ON ru.Id = ap.OwnerUserId
JOIN UserActivity ua ON ru.Id = ua.UserId
GROUP BY ru.Id, ru.DisplayName, ru.Reputation, ru.Views, ru.BadgeCount, ru.GoldBadges, ru.SilverBadges, ru.BronzeBadges
ORDER BY ru.Reputation DESC, TotalActivePosts DESC
LIMIT 10;
