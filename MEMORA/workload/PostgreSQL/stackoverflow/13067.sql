WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        AVG(U.Reputation) AS AvgUserReputation
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.Id, P.PostTypeId, P.CreationDate
)

SELECT 
    PT.Name AS PostType,
    COUNT(*) AS TotalPosts,
    AVG(CommentCount) AS AvgComments,
    AVG(VoteCount) AS AvgVotes,
    AVG(AvgUserReputation) AS AvgOwnerReputation
FROM 
    PostStats PS
JOIN 
    PostTypes PT ON PS.PostTypeId = PT.Id
GROUP BY 
    PT.Name
ORDER BY 
    TotalPosts DESC;