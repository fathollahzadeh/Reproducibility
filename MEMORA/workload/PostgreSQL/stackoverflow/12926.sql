
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        U.Reputation AS OwnerReputation,
        U.Location,
        COUNT(DISTINCT V.Id) AS VoteCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON p.Id = V.PostId
    LEFT JOIN 
        Comments C ON p.Id = C.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount, 
        p.AnswerCount, p.CommentCount, p.FavoriteCount, 
        U.Reputation, U.Location
),
PostTypeCounts AS (
    SELECT 
        pt.Id AS PostTypeId,
        pt.Name AS PostTypeName,
        COUNT(ps.PostId) AS PostCount,
        SUM(ps.ViewCount) AS TotalViews,
        SUM(ps.Score) AS TotalScore,
        AVG(ps.OwnerReputation) AS AvgOwnerReputation
    FROM 
        PostTypes pt
    LEFT JOIN 
        PostStats ps ON pt.Id = ps.PostTypeId
    GROUP BY 
        pt.Id, pt.Name
)
SELECT 
    ptc.PostTypeId,
    ptc.PostTypeName,
    ptc.PostCount,
    ptc.TotalViews,
    ptc.TotalScore,
    ptc.AvgOwnerReputation,
    (ptc.TotalScore * 1.0 / NULLIF(ptc.PostCount, 0)) AS AvgScorePerPost,
    (ptc.TotalViews * 1.0 / NULLIF(ptc.PostCount, 0)) AS AvgViewsPerPost
FROM 
    PostTypeCounts ptc
ORDER BY 
    ptc.PostTypeId;
