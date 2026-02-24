WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        COALESCE(badge_count.BadgeCount, 0) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            u.Id,
            COUNT(b.Id) AS BadgeCount
        FROM 
            Users u
        LEFT JOIN 
            Badges b ON u.Id = b.UserId
        WHERE 
            b.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        GROUP BY 
            u.Id
    ) badge_count ON badge_count.Id = rp.OwnerUserId
    WHERE 
        rp.Score > 10 AND rp.CommentCount > 5
),
HighlyLinkedPosts AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS LinkCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
),
FinalSelection AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.Score,
        pp.ViewCount,
        hl.LinkCount,
        pp.BadgeCount,
        CASE
            WHEN hl.LinkCount > 10 THEN 'Highly Linked'
            WHEN pp.BadgeCount > 5 THEN 'Badge Holder'
            ELSE 'Regular'
        END AS PostCategory
    FROM 
        PopularPosts pp
    LEFT JOIN 
        HighlyLinkedPosts hl ON pp.PostId = hl.PostId
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.Score,
    fs.ViewCount,
    fs.LinkCount,
    fs.BadgeCount,
    fs.PostCategory,
    ph.CreationDate AS LastEditDate,
    ph.UserDisplayName AS LastEditor
FROM 
    FinalSelection fs
LEFT JOIN 
    PostHistory ph ON fs.PostId = ph.PostId 
    AND ph.CreationDate = (
        SELECT MAX(sub_ph.CreationDate)
        FROM PostHistory sub_ph
        WHERE sub_ph.PostId = fs.PostId
    )
WHERE 
    fs.PostCategory <> 'Regular'
ORDER BY 
    fs.Score DESC, fs.ViewCount DESC
LIMIT 50;