
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
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
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, OwnerDisplayName, CommentCount, UpVotes, DownVotes
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
)
SELECT 
    f.OwnerDisplayName,
    COUNT(DISTINCT f.PostId) AS PostsCount,
    SUM(f.Score) AS TotalScore,
    SUM(f.ViewCount) AS TotalViews,
    AVG(f.CommentCount) AS AvgComments,
    AVG(f.UpVotes) AS AvgUpVotes,
    AVG(f.DownVotes) AS AvgDownVotes
FROM 
    FilteredPosts f
GROUP BY 
    f.OwnerDisplayName
ORDER BY 
    PostsCount DESC, TotalScore DESC
LIMIT 10;
