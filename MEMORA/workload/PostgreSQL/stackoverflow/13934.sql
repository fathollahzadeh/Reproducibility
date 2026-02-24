WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        (SELECT COUNT(*) FROM PostHistory PH WHERE PH.PostId = P.Id) AS HistoryCount
    FROM 
        Posts P
        LEFT JOIN Comments C ON P.Id = C.PostId
        LEFT JOIN Votes V ON P.Id = V.PostId
        LEFT JOIN Posts A ON P.Id = A.ParentId
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.Title, P.CreationDate
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.CommentCount,
    PS.VoteCount,
    PS.AnswerCount,
    PS.HistoryCount,
    (PS.CommentCount + PS.VoteCount + PS.AnswerCount + PS.HistoryCount) AS TotalEngagement
FROM 
    PostStats PS
ORDER BY 
    TotalEngagement DESC
LIMIT 10;