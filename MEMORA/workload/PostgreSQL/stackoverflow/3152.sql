
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
        AND p.PostTypeId = 1
),
FrequentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
QualityPosts AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.ViewCount,
        pp.Score,
        ph.Comment
    FROM 
        RankedPosts pp
    LEFT JOIN 
        PostHistory ph ON pp.PostId = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)
    WHERE 
        pp.Rank = 1
        AND pp.Score > 5
)
SELECT 
    fu.DisplayName,
    COALESCE(qp.Title, 'No Quality Posts') AS Title,
    COALESCE(qp.ViewCount, 0) AS ViewCount,
    COALESCE(qp.Score, 0) AS Score,
    CASE 
        WHEN qp.Comment IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    FrequentUsers fu
LEFT JOIN 
    QualityPosts qp ON fu.UserId = qp.PostId
ORDER BY 
    fu.PostCount DESC, 
    qp.Score DESC
LIMIT 20;
