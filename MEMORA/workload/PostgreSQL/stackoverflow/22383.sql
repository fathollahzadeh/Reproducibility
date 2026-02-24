WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostsWithBadges AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        ARRAY_AGG(DISTINCT b.Name) AS BadgeNames
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        ud.DisplayName,
        ud.Reputation,
        pwb.BadgeNames,
        CASE 
            WHEN rp.Score > 10 THEN 'High Score'
            WHEN rp.Score BETWEEN 5 AND 10 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    JOIN 
        UserDetails ud ON rp.OwnerUserId = ud.UserId
    LEFT JOIN 
        PostsWithBadges pwb ON rp.PostId = pwb.Id
    WHERE 
        rp.PostRank = 1 AND ud.Reputation > 100
)
SELECT 
    f.Title,
    f.DisplayName,
    f.Reputation,
    f.Score,
    f.ViewCount,
    f.BadgeNames,
    COALESCE((
        SELECT COUNT(*) 
        FROM Comments c 
        WHERE c.PostId = f.PostId
    ), 0) AS CommentCount,
    CASE 
        WHEN f.ViewCount IS NULL THEN 'No Views'
        ELSE 'Views Recorded'
    END AS ViewStatus
FROM 
    FilteredPosts f
ORDER BY 
    f.Score DESC,
    f.ViewCount DESC;