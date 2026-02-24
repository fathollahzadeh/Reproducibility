
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
PostHistoryDetail AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.CreationDate, ph.UserId, ph.Comment
),
UserPostStats AS (
    SELECT 
        um.UserId,
        COUNT(DISTINCT rp.PostId) AS TotalPosts,
        COALESCE(SUM(rp.Score), 0) AS TotalScore,
        COALESCE(SUM(rp.UpVotes), 0) AS TotalUpVotes,
        COALESCE(SUM(rp.DownVotes), 0) AS TotalDownVotes,
        COALESCE(MAX(rp.CreationDate), TIMESTAMP '1900-01-01') AS MostRecentPost
    FROM 
        UserMetrics um
    LEFT JOIN 
        RankedPosts rp ON um.UserId = rp.OwnerUserId
    GROUP BY 
        um.UserId
)
SELECT 
    ups.UserId,
    um.DisplayName,
    um.Reputation,
    um.GoldBadges,
    um.SilverBadges,
    um.BronzeBadges,
    ups.TotalPosts,
    ups.TotalScore,
    ups.TotalUpVotes,
    ups.TotalDownVotes,
    ups.MostRecentPost,
    phd.CloseCount,
    phd.ReopenCount
FROM 
    UserPostStats ups
JOIN 
    UserMetrics um ON ups.UserId = um.UserId
LEFT JOIN 
    PostHistoryDetail phd ON ups.TotalPosts > 0 AND phd.PostId IN (SELECT PostId FROM RankedPosts WHERE OwnerUserId = ups.UserId)
WHERE 
    ups.TotalPosts > 5 
    AND um.Reputation > 500
    AND (COALESCE(phd.CloseCount, 0) + COALESCE(phd.ReopenCount, 0)) > 0
ORDER BY 
    ups.TotalScore DESC
LIMIT 10;
