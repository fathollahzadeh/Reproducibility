
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(A.Id) AS AnswerCount,
        SUM(CASE WHEN V.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount,
        AVG(U.Reputation) AS AvgReputation
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.Id, P.PostTypeId, P.CreationDate
),
TagStats AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        T.Count,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.Id, T.TagName, T.Count
)
SELECT 
    PS.PostId,
    PS.PostTypeId,
    PS.CreationDate,
    PS.CommentCount,
    PS.AnswerCount,
    PS.VoteCount,
    PS.AvgReputation,
    TS.TagId,
    TS.TagName,
    TS.Count AS TagCount,
    TS.PostCount
FROM 
    PostStats PS
LEFT JOIN 
    TagStats TS ON PS.PostId = TS.TagId
ORDER BY 
    PS.CreationDate DESC
LIMIT 100;
