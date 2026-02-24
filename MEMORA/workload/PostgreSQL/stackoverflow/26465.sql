
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.PostTypeId,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId, u.DisplayName
),
StringProcess AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.BadgeCount,
        rp.ViewCount,
        rp.Score,
        CASE 
            WHEN rp.PostTypeId = 1 THEN 'Question'
            WHEN rp.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType,
        REPLACE(REPLACE(rp.Title, 'Stack Overflow', 'SO'), 'Help', 'Assistance') AS ProcessedTitle
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
)

SELECT 
    sp.PostId,
    sp.ProcessedTitle,
    sp.OwnerDisplayName,
    sp.CommentCount,
    sp.BadgeCount,
    sp.ViewCount,
    sp.Score,
    CASE 
        WHEN LENGTH(sp.ProcessedTitle) > 50 THEN 'Long Title'
        ELSE 'Short Title'
    END AS TitleLengthCategory
FROM 
    StringProcess sp
ORDER BY 
    sp.Score DESC, sp.ViewCount DESC;
