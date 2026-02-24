
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE(AVG(v.vote_score), 0) AS AverageVoteScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 WHEN vt.Name = 'DownMod' THEN -1 ELSE 0 END) AS vote_score 
        FROM 
            Votes v
        JOIN 
            VoteTypes vt ON v.VoteTypeId = vt.Id
        GROUP BY 
            PostId) v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, u.DisplayName, p.CreationDate, p.LastActivityDate
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        OwnerDisplayName, 
        CreationDate, 
        LastActivityDate, 
        CommentCount, 
        AverageVoteScore,
        ROW_NUMBER() OVER (ORDER BY AverageVoteScore DESC, CommentCount DESC) AS Rank
    FROM 
        RankedPosts
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.LastActivityDate,
    tp.CommentCount,
    tp.AverageVoteScore
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.AverageVoteScore DESC, tp.CommentCount DESC;
