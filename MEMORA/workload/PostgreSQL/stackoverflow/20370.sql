WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
VoteDetails AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
),
UserPerformance AS (
    SELECT 
        ub.UserId,
        ub.Reputation,
        COALESCE(pa.PostCount, 0) AS PostCount,
        COALESCE(pa.PositivePosts, 0) AS PositivePosts,
        COALESCE(pa.NegativePosts, 0) AS NegativePosts,
        COALESCE(vd.TotalVotes, 0) AS TotalVotes,
        COALESCE(vd.UpVotes, 0) AS UpVotes,
        COALESCE(vd.DownVotes, 0) AS DownVotes,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        UserBadgeStats ub
    LEFT JOIN 
        PostActivity pa ON ub.UserId = pa.OwnerUserId
    LEFT JOIN 
        VoteDetails vd ON ub.UserId = vd.UserId
)
SELECT 
    u.UserId,
    u.Reputation,
    u.PostCount,
    u.PositivePosts,
    u.NegativePosts,
    u.TotalVotes,
    u.UpVotes,
    u.DownVotes,
    u.BadgeCount,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges
FROM 
    UserPerformance u
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users) AND
    u.TotalVotes > 0
ORDER BY 
    u.BadgeCount DESC, u.Reputation DESC
LIMIT 10;