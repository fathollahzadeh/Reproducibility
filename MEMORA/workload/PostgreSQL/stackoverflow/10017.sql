WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2022-01-01'  
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate, p.ViewCount, p.Score
),
PostTypesStats AS (
    SELECT 
        pt.Id AS PostTypeId,
        pt.Name AS PostTypeName,
        COUNT(ps.PostId) AS TotalPosts,
        SUM(ps.ViewCount) AS TotalViews,
        SUM(ps.Score) AS TotalScore,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.VoteCount) AS TotalVotes,
        AVG(ps.UpVotes) AS AvgUpVotes,
        AVG(ps.DownVotes) AS AvgDownVotes
    FROM 
        PostStats ps
    JOIN 
        PostTypes pt ON ps.PostTypeId = pt.Id
    GROUP BY 
        pt.Id, pt.Name
)

SELECT 
    PostTypeId,
    PostTypeName,
    TotalPosts,
    TotalViews,
    TotalScore,
    TotalComments,
    TotalVotes,
    AvgUpVotes,
    AvgDownVotes
FROM 
    PostTypesStats
ORDER BY 
    TotalPosts DESC;