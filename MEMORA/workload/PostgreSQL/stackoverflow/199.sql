
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 100
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        us.UpVotes,
        us.DownVotes,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges
    FROM UserStatistics us
    WHERE us.Rank <= 10
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    COALESCE(rp.Title, 'No Recent Posts') AS LastPostTitle,
    COALESCE(rp.CreationDate, NULL) AS LastPostDate,
    CASE 
        WHEN tu.UpVotes > tu.DownVotes THEN 'Positive'
        ELSE 'Negative'
    END AS VoteSentiment
FROM TopUsers tu
LEFT JOIN RecentPosts rp ON tu.UserId = rp.OwnerUserId AND rp.RecentRank = 1
ORDER BY tu.Reputation DESC;
