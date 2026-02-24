WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
        LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),

TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        OwnerName,
        AnswerCount,
        CommentCount,
        VoteCount,
        ViewCount
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
    ORDER BY 
        ViewCount DESC
    LIMIT 10
)

SELECT 
    tp.Title,
    tp.OwnerName,
    tp.CreationDate,
    tp.AnswerCount,
    tp.CommentCount,
    tp.VoteCount,
    tp.ViewCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    TopPosts tp
    LEFT JOIN Posts p ON tp.PostId = p.Id
    LEFT JOIN LATERAL (
        SELECT 
            unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName
    ) t ON true
GROUP BY 
    tp.Title, tp.OwnerName, tp.CreationDate, tp.AnswerCount, tp.CommentCount, tp.VoteCount, tp.ViewCount
ORDER BY 
    tp.ViewCount DESC;