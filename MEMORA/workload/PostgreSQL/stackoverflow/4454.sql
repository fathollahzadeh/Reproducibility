
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(P.QuestionCount, 0) AS QuestionCount,
        COALESCE(A.AnswerCount, 0) AS AnswerCount,
        COALESCE(C.CommentCount, 0) AS CommentCount
    FROM 
        Users U
    LEFT JOIN (
        SELECT 
            OwnerUserId, 
            COUNT(*) AS QuestionCount
        FROM 
            Posts 
        WHERE 
            PostTypeId = 1 
        GROUP BY 
            OwnerUserId
    ) P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT 
            OwnerUserId, 
            COUNT(*) AS AnswerCount
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            OwnerUserId
    ) A ON U.Id = A.OwnerUserId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS CommentCount
        FROM 
            Comments 
        GROUP BY 
            UserId
    ) C ON U.Id = C.UserId
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS IsAccepted
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title
),
RankedPosts AS (
    SELECT 
        PS.*, 
        RANK() OVER (ORDER BY PS.TotalUpvotes DESC, PS.TotalDownvotes ASC) AS PostRank
    FROM 
        PostStatistics PS
)
SELECT 
    UA.DisplayName AS UserName,
    UA.Reputation,
    RP.Title,
    RP.TotalComments,
    RP.TotalUpvotes,
    RP.TotalDownvotes,
    RP.IsAccepted,
    RP.PostRank
FROM 
    UserActivity UA
JOIN 
    Posts P ON P.OwnerUserId = UA.UserId
JOIN 
    RankedPosts RP ON P.Id = RP.PostId
WHERE 
    UA.Reputation > 1000
    AND (RP.TotalComments > 5 OR RP.TotalUpvotes > 10)
ORDER BY 
    UA.Reputation DESC, 
    RP.PostRank;
