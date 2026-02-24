
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.AnswerCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        AnswerCount,
        OwnerName,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 10
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.AnswerCount,
    tp.CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3) AS DownVotes,
    (SELECT STRING_AGG(t.TagName, ', ') FROM Posts p JOIN Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%') WHERE p.Id = tp.PostId) AS TagsUsed
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
