
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (2) THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 12 THEN 1 ELSE 0 END), 0) AS SpamCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(LENGTH(p.Body)) AS AvgBodyLength
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'  
    GROUP BY 
        p.Id, p.PostTypeId
),
PostTypeSummary AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(ps.PostId) AS PostCount,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.UpVoteCount) AS TotalUpVotes,
        SUM(ps.DownVoteCount) AS TotalDownVotes,
        SUM(ps.SpamCount) AS TotalSpam,
        SUM(ps.TotalViews) AS TotalViews,
        AVG(ps.AvgBodyLength) AS AverageBodyLength
    FROM 
        PostStats ps
    JOIN 
        PostTypes pt ON ps.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)
SELECT 
    PostType,
    PostCount,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    TotalSpam,
    TotalViews,
    AverageBodyLength
FROM 
    PostTypeSummary
ORDER BY 
    PostCount DESC;
