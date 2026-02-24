
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(DISTINCT c.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
)
SELECT 
    u.DisplayName, 
    rp.PostId, 
    rp.Title, 
    rp.CommentCount, 
    rp.AnswerCount, 
    rp.UpVoteCount, 
    rp.DownVoteCount
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
WHERE 
    rp.Rank <= 5
ORDER BY 
    u.DisplayName, rp.CommentCount DESC;
