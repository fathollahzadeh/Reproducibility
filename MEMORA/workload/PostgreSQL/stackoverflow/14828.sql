
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        COALESCE(A.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(C.Id) AS CommentCount,
        MAX(P.CreationDate) AS LastActivityDate
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.AcceptedAnswerId = A.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.LastActivityDate >= CURRENT_TIMESTAMP - INTERVAL '1 YEAR'
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.Score, A.AcceptedAnswerId
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.CommentCount,
    P.PostId,
    P.Title,
    P.ViewCount,
    P.Score,
    P.AcceptedAnswerId,
    P.CommentCount AS PostCommentCount,
    P.LastActivityDate
FROM 
    UserStats U
JOIN 
    PostStats P ON U.UserId = P.AcceptedAnswerId
ORDER BY 
    U.Reputation DESC, P.ViewCount DESC
FETCH FIRST 100 ROWS ONLY;
