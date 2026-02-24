
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score AS PostScore,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT H.Id) AS EditCount,
        MAX(H.CreationDate) AS LastEditDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory H ON P.Id = H.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        TotalScore,
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserStats 
    WHERE 
        Reputation > 1000
)
SELECT 
    TU.UserRank,
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.TotalScore,
    PA.Title AS RecentPostTitle,
    PA.PostScore AS RecentPostScore,
    PA.CommentCount AS RecentPostCommentCount,
    PA.LastEditDate AS RecentPostLastEdit
FROM 
    TopUsers TU
LEFT JOIN 
    PostActivity PA ON TU.UserId = PA.PostId
WHERE 
    TU.UserRank <= 10
ORDER BY 
    TU.UserRank;
