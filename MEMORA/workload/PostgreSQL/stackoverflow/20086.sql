
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName
    FROM 
        Users u
    WHERE 
        u.Reputation < (SELECT AVG(Reputation) FROM Users) 
        AND u.Location IS NOT NULL
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserActivity AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        v.UserId
)
SELECT 
    up.DisplayName,
    up.Reputation,
    rb.PostId,
    rb.Title AS LatestPostTitle,
    rb.CreationDate AS LatestPostDate,
    rb.Score AS LatestPostScore,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ua.VoteCount AS RecentVoteCount,
    ua.UpVotes,
    ua.DownVotes,
    CASE 
        WHEN rb.Score < 0 THEN 'Needs Improvement'
        WHEN rb.Score BETWEEN 1 AND 10 THEN 'Moderate Engagement'
        ELSE 'Highly Engaged'
    END AS EngagementLevel,
    STRING_AGG(DISTINCT TRIM(REGEXP_REPLACE(rb.Tags, '[<>]', '')), ', ') AS ConcatenatedTags
FROM 
    UserReputation up
JOIN 
    RankedPosts rb ON up.UserId = rb.OwnerUserId
LEFT JOIN 
    UserBadges ub ON up.UserId = ub.UserId
LEFT JOIN 
    UserActivity ua ON up.UserId = ua.UserId
WHERE 
    rb.Rank = 1 
    AND ub.BadgeCount IS NOT NULL 
    AND ua.VoteCount IS NOT NULL
GROUP BY 
    up.DisplayName, up.Reputation, rb.PostId, rb.Title, rb.CreationDate, rb.Score,
    ub.BadgeCount, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges, 
    ua.VoteCount, ua.UpVotes, ua.DownVotes
HAVING 
    COUNT(DISTINCT rb.PostId) > 0
ORDER BY 
    up.Reputation DESC, rb.CreationDate DESC;
