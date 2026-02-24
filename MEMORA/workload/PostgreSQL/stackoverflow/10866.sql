WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        AVG(v.BountyAmount) AS AverageBounty,
        MAX(p.Score) AS MaxScore,
        MIN(p.Score) AS MinScore,
        COUNT(DISTINCT ph.Id) AS RevisionCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.PostTypeId
),
PostTypeSummary AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(ps.PostId) AS TotalPosts,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.VoteCount) AS TotalVotes,
        AVG(ps.AverageBounty) AS AvgBountyAcrossPosts,
        MAX(ps.MaxScore) AS MaxPostScore,
        MIN(ps.MinScore) AS MinPostScore,
        SUM(ps.RevisionCount) AS TotalRevisions
    FROM 
        PostStats ps
    JOIN 
        PostTypes pt ON ps.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

SELECT 
    *,
    ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
FROM 
    PostTypeSummary
ORDER BY 
    TotalPosts DESC;