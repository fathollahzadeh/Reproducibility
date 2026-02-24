
WITH RECURSIVE UserReputation AS (
    SELECT 
        Id, 
        Reputation, 
        CreationDate,
        LastAccessDate,
        DisplayName,
        0 AS Level
    FROM Users
    WHERE Reputation IS NOT NULL

    UNION ALL

    SELECT 
        U.Id, 
        U.Reputation, 
        U.CreationDate,
        U.LastAccessDate,
        U.DisplayName,
        UR.Level + 1
    FROM Users U
    JOIN UserReputation UR ON U.Id = UR.Id
    WHERE UR.Level < 5
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        MAX(P.CreationDate) AS LastActivityDate
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.OwnerUserId
),
TopPosters AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalComments,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS RN
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 100
    GROUP BY U.Id, U.DisplayName
)
SELECT 
    UR.DisplayName AS UserDisplayName,
    UR.Reputation,
    PP.TotalPosts,
    PP.TotalViews,
    PP.TotalAnswers,
    PP.TotalComments,
    PP.RN
FROM TopPosters PP
JOIN UserReputation UR ON PP.UserId = UR.Id
WHERE PP.RN <= 10
ORDER BY UR.Reputation DESC, PP.TotalPosts DESC;
