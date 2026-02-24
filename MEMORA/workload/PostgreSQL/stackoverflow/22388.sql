
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
TopPostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.PostRank,
        CASE 
            WHEN rp.PostRank = 1 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS PostCategory,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.PostId = u.Id  
    WHERE 
        rp.PostRank <= 5  
),
BadgesCount AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalResults AS (
    SELECT 
        t.Title,
        t.CreationDate,
        t.Score,
        t.ViewCount,
        t.PostCategory,
        COALESCE(b.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(b.BadgeNames, 'No Badges') AS UserBadges
    FROM 
        TopPostDetails t
    LEFT JOIN 
        BadgesCount b ON t.PostId = b.UserId  
)
SELECT 
    f.Title,
    f.CreationDate,
    f.Score,
    f.ViewCount,
    f.PostCategory,
    f.UserBadgeCount,
    f.UserBadges
FROM 
    FinalResults f
WHERE 
    f.Score > 10 AND 
    f.UserBadgeCount IS NOT NULL
ORDER BY 
    f.Score DESC, 
    f.CreationDate ASC
LIMIT 10;
