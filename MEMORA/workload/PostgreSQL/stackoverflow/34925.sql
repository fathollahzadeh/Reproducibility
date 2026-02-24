
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > DATE '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, p.AcceptedAnswerId
),
RecentUsers AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation
    FROM 
        Users
    WHERE 
        CreationDate >= (SELECT MAX(CreationDate) FROM Users) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        MAX(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        MAX(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    CASE
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer Included'
        ELSE 'No Accepted Answer'
    END AS AnswerStatus,
    CASE
        WHEN rp.ViewCount > (SELECT AVG(ViewCount) FROM Posts) THEN 'Above Average Views'
        ELSE 'Below Average Views'
    END AS ViewStatus
FROM 
    RecentUsers u
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    rp.Rank = 1
ORDER BY 
    u.Reputation DESC, rp.Score DESC;
