WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        AnswerCount, 
        Upvotes, 
        Downvotes, 
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    u.DisplayName AS Author,
    tp.Title,
    tp.CreationDate,
    tp.AnswerCount,
    tp.Upvotes,
    tp.Downvotes,
    tp.CommentCount,
    COALESCE(b.Name, 'No Badge') AS UserBadge,
    COUNT(l.Id) AS RelatedLinksCount
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.PostId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    PostLinks l ON tp.PostId = l.PostId
GROUP BY 
    u.DisplayName, tp.Title, tp.CreationDate, tp.AnswerCount, tp.Upvotes, tp.Downvotes, tp.CommentCount, b.Name
ORDER BY 
    tp.Upvotes DESC;