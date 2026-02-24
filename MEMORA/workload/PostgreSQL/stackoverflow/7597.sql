WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS TotalComments,
        AVG(COALESCE(v.VoteCount, 0)) AS AvgVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.CreationDate,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.Id) DESC) AS CommentRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            VoteTypeId, 
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId, VoteTypeId
    ) v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.TotalComments,
        rp.AvgVotes,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentRank <= 10
)
SELECT 
    tp.Title,
    tp.TotalComments,
    tp.AvgVotes,
    tp.UpVotes,
    tp.DownVotes,
    u.DisplayName,
    u.Reputation
FROM 
    TopPosts tp
JOIN 
    Posts p ON tp.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    u.Reputation > 1000 
ORDER BY 
    tp.TotalComments DESC;