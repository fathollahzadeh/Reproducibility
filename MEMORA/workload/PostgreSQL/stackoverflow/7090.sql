WITH UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        AVG(COALESCE(p.Score, 0)) AS AvgPostScore
    FROM Votes v
    JOIN Posts p ON v.PostId = p.Id
    GROUP BY v.UserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(uv.UpVotes, 0) AS UpVotes,
        COALESCE(uv.DownVotes, 0) AS DownVotes,
        COALESCE(ub.TotalBadges, 0) AS TotalBadges,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(uv.AvgPostScore, 0) AS AvgPostScore
    FROM Users u
    LEFT JOIN UserVotes uv ON u.Id = uv.UserId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ur.UpVotes,
    ur.DownVotes,
    ur.TotalBadges,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    ur.AvgPostScore,
    ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC) AS ReputationRank
FROM UserReputation ur
WHERE ur.Reputation > 1000
ORDER BY ur.Reputation DESC, ur.AvgPostScore DESC;
