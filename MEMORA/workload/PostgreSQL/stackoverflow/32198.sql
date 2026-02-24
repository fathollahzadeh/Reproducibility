
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        u.Reputation,
        p.OwnerUserId
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1  
      AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),

UserBadges AS (
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

RecentVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id
)

SELECT 
    rb.PostId,
    rb.Title,
    rb.CreationDate,
    rb.ViewCount,
    rb.AnswerCount,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    rv.VoteCount,
    rv.UpVotes,
    rv.DownVotes,
    CASE 
        WHEN rb.Rank = 1 THEN 'Most Viewed'
        WHEN rv.UpVotes > rv.DownVotes THEN 'Popular'
        ELSE 'Needs More Attention'
    END AS PostStatus
FROM RankedPosts rb
LEFT JOIN UserBadges ub ON rb.OwnerUserId = ub.UserId
LEFT JOIN RecentVotes rv ON rb.PostId = rv.PostId
WHERE rb.Reputation > 1000  
ORDER BY rb.ViewCount DESC, ub.BadgeCount DESC
LIMIT 50;
