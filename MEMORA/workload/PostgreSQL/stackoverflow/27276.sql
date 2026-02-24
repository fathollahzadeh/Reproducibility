
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        CONCAT(u.DisplayName, ' (', u.Reputation, ' pts)') AS UserProfile,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT DISTINCT unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName 
         FROM Posts) t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN pv.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN pv.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes pv ON p.Id = pv.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ub.UserProfile,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ups.PostsCreated,
    ups.UpvotesReceived,
    ups.DownvotesReceived,
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Tags
FROM 
    UserBadges ub
JOIN 
    UserPostStats ups ON ub.UserId = ups.UserId
LEFT JOIN 
    RecentPosts rp ON rp.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '7 days' 
ORDER BY 
    ub.BadgeCount DESC, 
    ups.UpvotesReceived DESC
LIMIT 10;
