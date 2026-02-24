WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(AVG(CAST(P.Score AS FLOAT)), 0) AS AverageScore,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        DENSE_RANK() OVER (ORDER BY SUM(P.ViewCount) DESC) AS ViewRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.QuestionCount,
        UA.AnswerCount,
        UA.AverageScore,
        UA.TotalViews
    FROM UserActivity UA
    WHERE UA.ViewRank <= 10
),
RecentVotes AS (
    SELECT 
        V.PostId,
        V.UserId,
        V.CreationDate,
        VT.Name AS VoteType
    FROM Votes V
    JOIN VoteTypes VT ON V.VoteTypeId = VT.Id
    WHERE V.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostsDetail AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        U.DisplayName AS Author,
        COALESCE(RV.TotalVotes, 0) AS RecentVotesCount,
        COALESCE(CH.ClosedCount, 0) AS ClosedPostCount
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS ClosedCount
        FROM PostHistory
        WHERE PostHistoryTypeId = 10  
        GROUP BY PostId
    ) CH ON P.Id = CH.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS TotalVotes
        FROM RecentVotes
        GROUP BY PostId
    ) RV ON P.Id = RV.PostId
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.AverageScore,
    TU.TotalViews,
    PD.Title AS PostTitle,
    PD.Author,
    PD.RecentVotesCount,
    PD.ClosedPostCount,
    (CASE WHEN PD.ClosedPostCount > 0 THEN 'Closed' ELSE 'Open' END) AS PostStatus
FROM TopUsers TU
JOIN PostsDetail PD ON PD.Author = TU.DisplayName
ORDER BY TU.TotalViews DESC, PD.RecentVotesCount DESC;