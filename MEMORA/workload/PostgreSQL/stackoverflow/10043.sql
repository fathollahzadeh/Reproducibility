
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(V.VoteCount, 0)) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.OwnerUserId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.PostCount,
    UA.QuestionCount,
    UA.AnswerCount,
    UA.TotalViews,
    UA.TotalVotes,
    PE.PostId,
    PE.Title,
    PE.CreationDate,
    PE.Score,
    PE.CommentCount,
    PE.TotalBounties
FROM 
    UserActivity UA 
LEFT JOIN 
    PostEngagement PE ON UA.UserId = PE.OwnerUserId
ORDER BY 
    UA.TotalVotes DESC, UA.TotalViews DESC;
