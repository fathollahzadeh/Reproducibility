WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId, p.AcceptedAnswerId
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

LastActivity AS (
    SELECT 
        p.OwnerUserId,
        MAX(p.LastActivityDate) AS LastPostActivity
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)

SELECT 
    u.Id AS OwnerUserId,
    u.DisplayName,
    COALESCE(b.GoldBadges, 0) AS GoldBadges,
    COALESCE(b.SilverBadges, 0) AS SilverBadges,
    COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN rp.UserPostRank = 1 THEN rp.PostId END) AS AcceptedAnswersCount,
    SUM(rp.UpVoteCount) AS TotalUpVotes,
    SUM(rp.DownVoteCount) AS TotalDownVotes,
    MAX(la.LastPostActivity) AS LastActivity,
    SUM(rp.CommentCount) AS TotalComments
FROM 
    Users u
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
LEFT JOIN 
    LastActivity la ON u.Id = la.OwnerUserId
WHERE 
    u.Reputation > 0
GROUP BY 
    u.Id, u.DisplayName, b.GoldBadges, b.SilverBadges, b.BronzeBadges
ORDER BY 
    TotalPosts DESC, u.DisplayName ASC
LIMIT 10;