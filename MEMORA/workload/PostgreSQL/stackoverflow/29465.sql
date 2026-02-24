WITH RankedVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        v.VoteTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY v.CreationDate DESC) AS VoteRank
    FROM 
        Posts p
    JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        v.VoteTypeId IN (2, 3) 
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        RankedVotes 
    WHERE 
        VoteRank = 1 
    GROUP BY 
        PostId, Title
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pc.CommentCount,
        pc.UserDisplayName
    FROM 
        Posts p
    JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS CommentCount, 
            STRING_AGG(DISTINCT UserDisplayName, ', ') AS UserDisplayName
         FROM 
            Comments 
         GROUP BY 
            PostId) pc ON p.Id = pc.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.UpVotes,
    tp.DownVotes,
    tp.TotalVotes,
    pc.CommentCount,
    pc.UserDisplayName
FROM 
    TopPosts tp
LEFT JOIN 
    PostsWithComments pc ON tp.PostId = pc.PostId
WHERE 
    tp.TotalVotes > 0 
ORDER BY 
    tp.UpVotes DESC, 
    tp.DownVotes ASC, 
    pc.CommentCount DESC 
LIMIT 10;