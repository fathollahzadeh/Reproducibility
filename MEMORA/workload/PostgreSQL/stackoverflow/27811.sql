
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        rn = 1  
)
SELECT 
    MIN(PostId) AS MinPostId,
    MAX(PostId) AS MaxPostId,
    COUNT(*) AS TotalPosts,
    SUM(CommentCount) AS TotalComments,
    SUM(UpVoteCount) AS TotalUpVotes,
    SUM(DownVoteCount) AS TotalDownVotes,
    AVG(UpVoteCount - DownVoteCount) AS AverageVoteBalance
FROM 
    FilteredPosts
GROUP BY 
    OwnerDisplayName
ORDER BY 
    AverageVoteBalance DESC
LIMIT 10;
