WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(u.DisplayName, 'Community User') AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        AnswerCount,
        Author
    FROM 
        RankedPosts
    WHERE 
        Rank = 1
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.AnswerCount,
    tp.Author,
    pt.Name AS PostTypeName,
    COALESCE(bt.BadgeCount, 0) AS AuthorBadgeCount
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON 1 = pt.Id
LEFT JOIN (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
) bt ON bt.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
ORDER BY 
    tp.ViewCount DESC
LIMIT 10;