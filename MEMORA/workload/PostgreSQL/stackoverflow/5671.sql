
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' AND 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        OwnerDisplayName, 
        CommentCount, 
        UpVoteCount, 
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        OwnerPostRank <= 5  
)
SELECT 
    tp.OwnerDisplayName,
    COUNT(tp.PostId) AS TotalPosts,
    AVG(tp.Score) AS AverageScore,
    SUM(tp.ViewCount) AS TotalViewCount,
    SUM(tp.CommentCount) AS TotalComments,
    SUM(tp.UpVoteCount) AS TotalUpVotes,
    SUM(tp.DownVoteCount) AS TotalDownVotes
FROM 
    TopPosts tp
GROUP BY 
    tp.OwnerDisplayName
ORDER BY 
    TotalPosts DESC, 
    AverageScore DESC
LIMIT 10;
