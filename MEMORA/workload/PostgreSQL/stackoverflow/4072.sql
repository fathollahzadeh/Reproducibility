WITH UserVotes AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
), 
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(*) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), 
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
), 
ClosedPosts AS (
    SELECT 
        ph.UserId, 
        COUNT(DISTINCT ph.PostId) AS ClosedPostCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(uv.UpVotes, 0) AS UpVotes,
    COALESCE(uv.DownVotes, 0) AS DownVotes,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.AvgScore, 0) AS AvgScore,
    COALESCE(ps.Questions, 0) AS Questions,
    COALESCE(ps.Answers, 0) AS Answers,
    COALESCE(cp.ClosedPostCount, 0) AS ClosedPosts
FROM 
    Users u
LEFT JOIN 
    UserVotes uv ON u.Id = uv.UserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON u.Id = cp.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC
LIMIT 50;