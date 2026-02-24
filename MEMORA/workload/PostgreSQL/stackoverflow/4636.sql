WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.GoldBadges, 0) AS GoldBadgeCount,
        COALESCE(ub.SilverBadges, 0) AS SilverBadgeCount,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadgeCount
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    WHERE u.Reputation > 1000
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.GoldBadgeCount,
    tu.SilverBadgeCount,
    tu.BronzeBadgeCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(pv.Upvotes, 0) AS Upvotes,
    COALESCE(pv.Downvotes, 0) AS Downvotes,
    CASE 
        WHEN pv.Upvotes > pv.Downvotes THEN 'Positive'
        WHEN pv.Upvotes < pv.Downvotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM TopUsers tu
JOIN RankedPosts rp ON tu.Id = rp.OwnerUserId
LEFT JOIN PostVotes pv ON rp.PostId = pv.PostId
WHERE rp.PostRank = 1
ORDER BY tu.Reputation DESC, rp.CreationDate DESC
LIMIT 100;