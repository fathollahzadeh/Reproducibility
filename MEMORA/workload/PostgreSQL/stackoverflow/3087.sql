WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(rp.PostId) AS PostCount,
        SUM(rp.ViewCount) AS TotalViews,
        AVG(rp.Score) AS AverageScore
    FROM 
        RecentPosts rp
    WHERE 
        rp.rn = 1
    GROUP BY 
        rp.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
)
SELECT 
    u.DisplayName,
    COALESCE(ps.PostCount, 0) AS PostCount,
    COALESCE(ps.TotalViews, 0) AS TotalViews,
    COALESCE(ps.AverageScore, 0.0) AS AverageScore,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(uv.VoteCount, 0) AS TotalVotes,
    COALESCE(uv.UpVotes, 0) AS UpVotes,
    COALESCE(uv.DownVotes, 0) AS DownVotes
FROM 
    Users u
LEFT JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    UserVotes uv ON u.Id = uv.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    ps.PostCount DESC, 
    u.DisplayName;