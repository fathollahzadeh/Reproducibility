
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
), 
PostCategories AS (
    SELECT 
        pt.Name AS PostType,
        r.PostId,
        r.Title,
        r.CreationDate,
        r.ViewCount,
        r.Score,
        r.CommentCount,
        r.UpVoteCount,
        r.DownVoteCount,
        r.Rank
    FROM 
        RankedPosts r
    JOIN 
        PostTypes pt ON r.PostId = pt.Id
)
SELECT 
    pc.PostType,
    COUNT(*) AS TotalPosts,
    AVG(pc.ViewCount) AS AvgViews,
    SUM(pc.Score) AS TotalScore,
    SUM(pc.CommentCount) AS TotalComments,
    SUM(pc.UpVoteCount) AS TotalUpVotes,
    SUM(pc.DownVoteCount) AS TotalDownVotes
FROM 
    PostCategories pc
GROUP BY 
    pc.PostType
HAVING 
    COUNT(*) > 5
ORDER BY 
    TotalScore DESC;
