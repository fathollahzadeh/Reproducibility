
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.CreationDate >= '2020-01-01'
    GROUP BY 
        p.Id, p.Title, p.Score, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        (rp.UpVotes - rp.DownVotes) AS VoteBalance,
        rp.CommentCount,
        ub.BadgeCount,
        ub.HighestBadgeClass,
        rp.OwnerUserId
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.Score > 0 AND rp.CommentCount > 5
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.Score,
    pp.VoteBalance,
    pp.CommentCount,
    ub.DisplayName AS OwnerName,
    ub.Reputation,
    (CASE 
        WHEN pp.HighestBadgeClass = 1 THEN 'Gold' 
        WHEN pp.HighestBadgeClass = 2 THEN 'Silver' 
        WHEN pp.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'None' 
     END) AS HighestBadge
FROM 
    PopularPosts pp
JOIN 
    Users ub ON pp.OwnerUserId = ub.Id
WHERE 
    pp.BadgeCount > 0
    AND pp.CommentCount >= 10
ORDER BY 
    pp.VoteBalance DESC,
    pp.Score DESC
FETCH FIRST 100 ROWS ONLY;
