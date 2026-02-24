WITH RankedPosts AS (
    SELECT 
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2) 
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopPosts AS (
    SELECT 
        rp.Title,
        rp.OwnerDisplayName,
        rb.BadgeCount,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges rb ON rp.OwnerUserId = rb.UserId
    WHERE 
        rp.Rank <= 5
)

SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.BadgeCount,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - tp.CreationDate)) / 3600 AS AgeInHours
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;