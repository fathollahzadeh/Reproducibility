
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        p.OwnerUserId,
        p.CreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AcceptedAnswerId, p.OwnerUserId, p.CreationDate
),
TopPosts AS (
    SELECT 
        post.*,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        b.Name AS BadgeName
    FROM 
        RankedPosts post
    JOIN 
        Users u ON post.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        post.Rank = 1
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.AcceptedAnswerId,
    tp.OwnerDisplayName,
    tp.Reputation,
    tp.BadgeName,
    (SELECT COUNT(*) FROM Posts p WHERE p.ParentId = tp.PostId) AS AnswerCount
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC
FETCH FIRST 10 ROWS ONLY; 
