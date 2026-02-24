
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),

TrendingPosts AS (
    SELECT 
        rp.*,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS TotalUpVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
        AND rp.AnswerCount > 0
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.AnswerCount,
    tp.CommentCount,
    tp.TotalUpVotes,
    CASE 
        WHEN tp.AnswerCount >= 5 AND tp.TotalUpVotes >= 10 THEN 'Hot' 
        WHEN tp.AnswerCount < 5 AND tp.TotalUpVotes < 10 THEN 'New' 
        ELSE 'Moderate' 
    END AS PostStatus
FROM 
    TrendingPosts tp
ORDER BY 
    tp.TotalUpVotes DESC, tp.AnswerCount DESC;
