WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.Title,
        P.CreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS HasAcceptedAnswer
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    GROUP BY 
        P.Id, P.PostTypeId, P.Title, P.CreationDate
),
PostTypeAverages AS (
    SELECT 
        PostTypeId,
        AVG(CommentCount) AS AvgCommentCount,
        AVG(VoteCount) AS AvgVoteCount,
        AVG(BadgeCount) AS AvgBadgeCount,
        AVG(HasAcceptedAnswer) AS AvgHasAcceptedAnswer
    FROM 
        PostStatistics
    GROUP BY 
        PostTypeId
)
SELECT 
    PT.Name AS PostTypeName,
    PTA.AvgCommentCount,
    PTA.AvgVoteCount,
    PTA.AvgBadgeCount,
    PTA.AvgHasAcceptedAnswer
FROM 
    PostTypeAverages PTA
JOIN 
    PostTypes PT ON PTA.PostTypeId = PT.Id
ORDER BY 
    PT.Id;
