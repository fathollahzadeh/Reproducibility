
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        SUM(CASE WHEN v.VoteTypeId = 9 THEN v.BountyAmount ELSE 0 END) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '90 days' 
        AND p.Score IS NOT NULL 
    GROUP BY 
        p.Id, p.Title, p.Score, u.DisplayName, p.PostTypeId
),
RecentBadges AS (
    SELECT 
        b.UserId,
        ARRAY_AGG(b.Name) AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '365 days'
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.OwnerName,
    COALESCE(rb.BadgeNames, ARRAY[]::text[]) AS BadgeNames,
    rp.CommentCount,
    rp.Rank,
    rp.TotalBounty
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentBadges rb ON rp.OwnerName = (SELECT DisplayName FROM Users WHERE Id = rb.UserId)
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC
LIMIT 10;
