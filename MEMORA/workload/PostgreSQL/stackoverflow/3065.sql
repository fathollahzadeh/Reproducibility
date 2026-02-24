WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyEarned,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostDetails AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        us.UserId,
        us.Reputation,
        us.TotalBountyEarned,
        us.BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.Rank <= 3
)
SELECT 
    pd.PostId, 
    pd.Title, 
    pd.CreationDate, 
    pd.ViewCount, 
    pd.Reputation, 
    pd.TotalBountyEarned, 
    pd.BadgeCount,
    (
        SELECT STRING_AGG(t.TagName, ', ') 
        FROM Tags t 
        JOIN Posts p ON t.ExcerptPostId = p.Id 
        WHERE p.Id = pd.PostId
    ) AS Tags
FROM 
    PostDetails pd
ORDER BY 
    pd.ViewCount DESC
LIMIT 10;