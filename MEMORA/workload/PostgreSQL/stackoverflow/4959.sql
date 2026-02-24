
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.ViewCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.OwnerUserId,
        PD.ViewCount
    FROM PostDetails PD
    WHERE PD.PostRank = 1
)
SELECT 
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.TotalQuestions,
    US.TotalAnswers,
    TP.Title AS TopPostTitle,
    TP.CreationDate AS TopPostDate,
    TP.ViewCount AS TopPostViews,
    CASE 
        WHEN US.TotalUpvotes > US.TotalDownvotes THEN 'Positive'
        WHEN US.TotalUpvotes < US.TotalDownvotes THEN 'Negative'
        ELSE 'Neutral'
    END AS UserVoteSentiment
FROM UserStats US
LEFT JOIN TopPosts TP ON US.UserId = TP.OwnerUserId
ORDER BY US.Reputation DESC, TopPostViews DESC NULLS LAST;
