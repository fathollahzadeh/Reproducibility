
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= (DATE '2024-10-01' - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
), TopUserPosts AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostId) AS TotalPosts,
        AVG(Score) AS AverageScore,
        SUM(CommentCount) AS TotalComments,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        RankedPosts 
    WHERE 
        PostRank <= 3
    GROUP BY 
        OwnerDisplayName
)
SELECT 
    OwnerDisplayName,
    TotalPosts,
    AverageScore,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes
FROM 
    TopUserPosts
ORDER BY 
    TotalUpVotes DESC, TotalComments DESC;
