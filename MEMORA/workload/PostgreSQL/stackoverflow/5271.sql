WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2) 
),
TopPosts AS (
    SELECT 
        rp.*, 
        (SELECT COUNT(DISTINCT c.Id) FROM Comments c WHERE c.PostId = rp.Id) AS TotalComments,
        (SELECT COUNT(DISTINCT v.Id) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(DISTINCT v.Id) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount,
    tp.CommentCount,
    tp.OwnerDisplayName,
    tp.TotalComments,
    tp.UpVotes,
    tp.DownVotes,
    CASE 
        WHEN tp.Score >= 100 THEN 'High Score'
        WHEN tp.Score >= 50 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC;