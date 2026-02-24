WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score > 0
    GROUP BY 
        p.Id, u.DisplayName, p.PostTypeId
),
TopRankedPosts AS (
    SELECT 
        Id, Title, Score, CreationDate, OwnerDisplayName, CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        b.UserId
),
UserReputation AS (
    SELECT 
        u.Id,
        u.Reputation,
        CASE 
            WHEN rb.BadgeCount IS NOT NULL AND rb.BadgeCount > 0 THEN 'Active Contributor'
            ELSE 'Regular Contributor'
        END AS ContributionStatus
    FROM 
        Users u
    LEFT JOIN 
        RecentBadges rb ON u.Id = rb.UserId
)
SELECT 
    trp.Title,
    trp.Score,
    trp.CommentCount,
    trp.OwnerDisplayName,
    ur.Reputation,
    ur.ContributionStatus
FROM 
    TopRankedPosts trp
JOIN 
    UserReputation ur ON trp.OwnerDisplayName = ur.Id::varchar
ORDER BY 
    trp.Score DESC, trp.CommentCount DESC
LIMIT 10;