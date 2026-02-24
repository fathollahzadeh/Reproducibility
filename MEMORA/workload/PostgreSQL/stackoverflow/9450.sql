WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(v.Id) AS TotalVotesCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS PostsCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(p.Score) AS AvgScore,
        AVG(p.ViewCount) AS AvgViews
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
BadgeSummary AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgesCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    us.UpVotesCount,
    us.DownVotesCount,
    us.TotalVotesCount,
    ps.PostsCount,
    ps.TotalScore,
    ps.TotalViews,
    ps.AvgScore,
    ps.AvgViews,
    bs.BadgesCount,
    bs.GoldBadges,
    bs.SilverBadges,
    bs.BronzeBadges
FROM 
    Users u
LEFT JOIN 
    UserVoteSummary us ON u.Id = us.UserId
LEFT JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    BadgeSummary bs ON u.Id = bs.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC, us.UpVotesCount DESC
LIMIT 100;
