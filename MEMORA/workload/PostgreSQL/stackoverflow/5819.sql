
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        Rank,
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerDisplayName,
        CommentCount,
        AnswerCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.OwnerDisplayName,
    trp.CommentCount,
    trp.AnswerCount,
    COALESCE(b.Name, 'No Badge') AS UserBadge,
    EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - trp.CreationDate)) / 3600 AS AgeInHours
FROM 
    TopRankedPosts trp
LEFT JOIN 
    Badges b ON b.UserId = (
        SELECT Id FROM Users WHERE DisplayName = trp.OwnerDisplayName LIMIT 1
    ) 
ORDER BY 
    trp.Score DESC, trp.CommentCount DESC;
