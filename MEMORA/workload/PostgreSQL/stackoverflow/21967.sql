
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        U.Reputation AS OwnerReputation,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR' 
        AND (p.Title IS NOT NULL AND LENGTH(p.Title) > 0)
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, U.Reputation
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CommentCount,
    rp.RankScore,
    CASE 
        WHEN cp.LastClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open' 
    END AS PostStatus,
    COALESCE(ub.TotalBadges, 0) AS UserBadgeCount,
    COALESCE(ub.BadgeNames, 'No Badges') AS UserBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    UserBadges ub ON rp.OwnerReputation = ub.UserId
WHERE 
    rp.RankScore <= 5
ORDER BY 
    rp.RankScore, rp.Score DESC;
