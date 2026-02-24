WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT p2.Id) AS AnswerCount,
        RANK() OVER (ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts p2 ON p.Id = p2.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
TopRankedPosts AS (
    SELECT *
    FROM RankedPosts
    WHERE Rank <= 10
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.ViewCount,
    trp.UpVotes,
    trp.DownVotes,
    trp.CommentCount,
    trp.AnswerCount,
    ut.DisplayName AS OwnerDisplayName,
    ut.Reputation AS OwnerReputation
FROM 
    TopRankedPosts trp
JOIN 
    Users ut ON ut.Id = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = trp.PostId)
ORDER BY 
    trp.Rank, trp.ViewCount DESC;