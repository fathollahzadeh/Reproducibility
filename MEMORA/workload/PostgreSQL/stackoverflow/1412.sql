
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
UserVoteStats AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPostsVoted
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        p.LastActivityDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        v.UserId
), 
BadgesCount AS (
    SELECT 
        UserId,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(bs.GoldBadges, 0) AS GoldBadges,
    COALESCE(bs.SilverBadges, 0) AS SilverBadges,
    COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(uv.UpVotes, 0) AS TotalUpVotes,
    COALESCE(uv.DownVotes, 0) AS TotalDownVotes,
    COUNT(rp.PostId) FILTER (WHERE rp.Rank <= 10) AS TopPostsCount
FROM 
    Users u
LEFT JOIN 
    UserVoteStats uv ON u.Id = uv.UserId
LEFT JOIN 
    BadgesCount bs ON u.Id = bs.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id, u.DisplayName, bs.GoldBadges, bs.SilverBadges, bs.BronzeBadges, uv.UpVotes, uv.DownVotes
ORDER BY 
    TotalUpVotes DESC, TotalDownVotes ASC;
