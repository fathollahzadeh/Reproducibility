
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
PostRank AS (
    SELECT
        *,
        RANK() OVER (ORDER BY CreationDate DESC) AS PostRank
    FROM 
        RankedPosts
)
SELECT 
    pr.PostId,
    pr.Title,
    pr.CreationDate,
    pr.Owner,
    pr.CommentCount,
    pr.AnswerCount,
    pr.UpVotes - pr.DownVotes AS Score,
    pr.PostRank
FROM 
    PostRank pr
WHERE 
    pr.rn = 1 AND pr.PostRank <= 10
ORDER BY 
    pr.PostRank;
