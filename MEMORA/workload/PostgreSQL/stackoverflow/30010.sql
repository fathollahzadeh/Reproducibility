
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        COUNT(DISTINCT c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= CURRENT_TIMESTAMP - INTERVAL '6 months' 
    GROUP BY 
        b.UserId
),
OpenQuestions AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        RecentBadges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.PostTypeId = 1 AND 
        p.ClosedDate IS NULL 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Author,
    rp.CommentCount,
    CASE 
        WHEN op.BadgeCount > 0 THEN 'Has Badges: ' || op.BadgeCount
        ELSE 'No Badges'
    END AS BadgeInfo
FROM 
    RankedPosts rp
LEFT JOIN 
    OpenQuestions op ON rp.PostId = op.Id
WHERE 
    rp.PostRank <= 10 
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
