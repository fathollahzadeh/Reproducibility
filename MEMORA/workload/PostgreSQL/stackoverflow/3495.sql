
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(cs.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments cs ON p.Id = cs.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.Score, p.ViewCount, p.CreationDate
), UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), Summary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.CommentCount,
        rp.Upvotes,
        rp.Downvotes,
        CASE 
            WHEN ub.BadgeCount > 0 THEN 'Has Badges'
            ELSE 'No Badges'
        END AS BadgeStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UsersWithBadges ub ON rp.OwnerUserId = ub.UserId
)
SELECT 
    s.Title,
    s.ViewCount,
    s.CommentCount,
    s.Upvotes,
    s.Downvotes,
    s.BadgeStatus
FROM 
    Summary s
WHERE 
    s.BadgeStatus = 'Has Badges'
ORDER BY 
    s.ViewCount DESC
LIMIT 10;
