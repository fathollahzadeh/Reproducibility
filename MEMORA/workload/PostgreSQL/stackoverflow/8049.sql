
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.Score ELSE 0 END) AS QuestionScore,
        SUM(CASE WHEN P.PostTypeId = 2 THEN P.Score ELSE 0 END) AS AnswerScore,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostInteraction AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostsCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostLinks PL ON P.Id = PL.PostId
    GROUP BY 
        P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.BadgeCount,
        US.QuestionScore,
        US.AnswerScore,
        US.PostCount,
        COALESCE(PI.CommentCount, 0) AS CommentCount,
        COALESCE(PI.VoteCount, 0) AS VoteCount,
        COALESCE(PI.RelatedPostsCount, 0) AS RelatedPostsCount
    FROM 
        UserStats US
    LEFT JOIN 
        PostInteraction PI ON US.UserId = PI.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    BadgeCount,
    QuestionScore,
    AnswerScore,
    PostCount,
    CommentCount,
    VoteCount,
    RelatedPostsCount
FROM 
    CombinedStats
WHERE 
    Reputation > 1000
ORDER BY 
    Reputation DESC, BadgeCount DESC, PostCount DESC
FETCH FIRST 100 ROWS ONLY;
