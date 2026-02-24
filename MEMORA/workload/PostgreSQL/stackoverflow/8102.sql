
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, u.DisplayName, p.PostTypeId, p.Score
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.CreationDate,
    pp.OwnerDisplayName,
    pp.AnswerCount,
    pp.CommentCount,
    b.Name AS BadgeName,
    bh.Date AS BadgeDate
FROM 
    PopularPosts pp
LEFT JOIN 
    Badges b ON pp.PostId = b.UserId
LEFT JOIN 
    Users u ON pp.OwnerDisplayName = u.DisplayName
LEFT JOIN 
    (SELECT UserId, MIN(Date) AS Date FROM Badges GROUP BY UserId) bh ON u.Id = bh.UserId
ORDER BY 
    pp.ViewCount DESC;
