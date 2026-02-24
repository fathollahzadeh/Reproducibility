WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '5 years' 
        AND (p.Score IS NOT NULL OR p.ViewCount > 100)
), 
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        bg.Name AS BadgeName,
        COALESCE(lt.Name, 'None') AS LinkTypeName,
        COUNT(c.Id) AS CommentCount
    FROM RankedPosts rp
    LEFT JOIN Badges bg ON bg.UserId = rp.OwnerUserId AND bg.Class = 1
    LEFT JOIN PostLinks pl ON pl.PostId = rp.PostId
    LEFT JOIN LinkTypes lt ON pl.LinkTypeId = lt.Id
    LEFT JOIN Comments c ON c.PostId = rp.PostId
    WHERE 
        rp.Rank <= 3
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.OwnerUserId, rp.Score, rp.ViewCount, rp.AnswerCount, bg.Name, lt.Name
)

SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    u.DisplayName,
    pp.Score,
    pp.ViewCount,
    pp.AnswerCount,
    pp.CommentCount,
    pp.BadgeName,
    pp.LinkTypeName,
    CASE
        WHEN pp.BadgeName IS NOT NULL THEN 'Achieved'
        ELSE 'Not Achieved'
    END AS BadgeStatus,
    CASE 
        WHEN pp.Score > 50 THEN 'Highly Rated'
        WHEN pp.Score BETWEEN 20 AND 50 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS ScoreCategory,
    CASE 
        WHEN pp.ViewCount IS NULL THEN 'No Views Available'
        ELSE 'Views Available'
    END AS ViewStatus
FROM 
    PopularPosts pp
LEFT JOIN Users u ON pp.OwnerUserId = u.Id
WHERE 
    pp.CommentCount < 5 
    OR pp.Score < 10
ORDER BY 
    pp.ViewCount DESC, 
    pp.Score DESC
LIMIT 100;