
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(a.Id) DESC) AS RankByAnswers
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.OwnerDisplayName, 
    rp.AnswerCount, 
    rp.CommentCount, 
    rp.UpVotes, 
    rp.DownVotes
FROM 
    RankedPosts rp
WHERE 
    rp.RankByAnswers <= 5
ORDER BY 
    rp.AnswerCount DESC, 
    rp.UpVotes DESC
LIMIT 10;
