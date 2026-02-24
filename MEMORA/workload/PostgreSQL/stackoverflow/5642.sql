
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        * 
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 5
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.OwnerDisplayName,
    trp.VoteCount,
    trp.CommentCount,
    trp.BadgeCount,
    pt.Name AS PostTypeName,
    pt2.Name AS LastEditorPostType
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostTypes pt ON trp.PostId IN (SELECT p.Id FROM Posts p WHERE p.PostTypeId = pt.Id)
LEFT JOIN 
    Posts p2 ON trp.PostId = p2.AcceptedAnswerId
LEFT JOIN 
    PostTypes pt2 ON p2.PostTypeId = pt2.Id
ORDER BY 
    trp.Score DESC, trp.CreationDate DESC;
