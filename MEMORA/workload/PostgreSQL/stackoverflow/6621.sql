WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.OwnerDisplayName,
    EXISTS (
        SELECT 
            1 
        FROM 
            Votes v 
        WHERE 
            v.PostId = tp.PostId 
            AND v.VoteTypeId = 2  
    ) AS HasUpVotes,
    EXISTS (
        SELECT 
            1 
        FROM 
            Votes v 
        WHERE 
            v.PostId = tp.PostId 
            AND v.VoteTypeId = 3  
    ) AS HasDownVotes
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC;