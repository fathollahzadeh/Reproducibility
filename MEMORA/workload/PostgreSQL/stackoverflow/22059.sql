WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankPerType,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate ASC) AS PostOrder
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    WHERE
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        RankPerType,
        PostOrder
    FROM
        RankedPosts
    WHERE
        RankPerType <= 5
),
Notifications AS (
    SELECT
        u.DisplayName AS UserDisplayName,
        p.Title,
        COALESCE(b.Name, 'No Badge') AS BadgeName
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId AND b.Class = 1
    JOIN
        Posts p ON u.Id = p.OwnerUserId
    WHERE
        p.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
        AND u.Reputation > (SELECT AVG(Reputation) FROM Users)
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    img.UserDisplayName,
    img.BadgeName
FROM 
    TopPosts tp
FULL OUTER JOIN 
    Notifications img ON img.Title = tp.Title
WHERE 
    tp.PostOrder % 2 = 0 OR img.BadgeName <> 'No Badge'
ORDER BY 
    tp.Score DESC, img.UserDisplayName;