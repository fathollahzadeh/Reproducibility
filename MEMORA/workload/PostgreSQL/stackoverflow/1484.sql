WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS PostCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT UserId, DisplayName, Reputation, UpVotes, DownVotes, PostCount, QuestionCount, AnswerCount
    FROM UserStats
    WHERE Rank <= 10
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.LastActivityDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        P.OwnerUserId,
        P.AcceptedAnswerId,
        COALESCE((SELECT COUNT(*) FROM Posts P2 WHERE P2.ParentId = P.Id AND P2.PostTypeId = 2), 0) AS RelatedAnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.LastActivityDate, P.OwnerUserId, P.AcceptedAnswerId
)
SELECT 
    U.DisplayName AS TopUser,
    U.Reputation,
    P.Title AS PostTitle,
    P.ViewCount,
    P.CommentCount,
    P.TotalUpVotes,
    P.TotalDownVotes,
    P.RelatedAnswerCount,
    CASE 
        WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS HasAcceptedAnswer,
    CASE 
        WHEN P.ViewCount > 1000 THEN 'Hot' 
        ELSE 'Normal' 
    END AS PostStatus
FROM 
    TopUsers U
JOIN 
    PostActivity P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.Reputation DESC, P.ViewCount DESC
