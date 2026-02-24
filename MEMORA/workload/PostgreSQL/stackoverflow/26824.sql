
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),

TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Tags, 
        OwnerDisplayName, 
        CreationDate, 
        ViewCount, 
        Score
    FROM 
        RankedPosts
    WHERE 
        Rank = 1
),

PostStats AS (
    SELECT 
        p.PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(ph.CreationDate) AS LastActivityDate
    FROM 
        TopPosts p
    LEFT JOIN 
        Comments c ON p.PostId = c.PostId
    LEFT JOIN 
        Votes v ON p.PostId = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.PostId = ph.PostId
    GROUP BY 
        p.PostId
)

SELECT 
    t.Title,
    t.Tags,
    t.OwnerDisplayName,
    ps.CommentCount,
    ps.VoteCount,
    ps.LastActivityDate,
    CASE 
        WHEN ps.VoteCount > 100 THEN 'Highly Voted'
        WHEN ps.VoteCount BETWEEN 50 AND 100 THEN 'Moderately Voted'
        ELSE 'Low Votes'
    END AS VoteCategory
FROM 
    TopPosts t
JOIN 
    PostStats ps ON t.PostId = ps.PostId
ORDER BY 
    ps.VoteCount DESC, 
    t.CreationDate DESC;
