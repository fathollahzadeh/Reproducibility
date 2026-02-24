WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        UpVotes,
        DownVotes,
        QuestionCount,
        AnswerCount,
        TotalViews,
        RANK() OVER (ORDER BY Reputation DESC, TotalViews DESC, BadgeCount DESC) AS UserRank
    FROM UserStats
),
TopUsers AS (
    SELECT 
        *
    FROM RankedUsers
    WHERE UserRank <= 10
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.BadgeCount,
    TU.UpVotes,
    TU.DownVotes,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.TotalViews,
    PT.Name AS PostType
FROM TopUsers TU
JOIN Posts P ON TU.UserId = P.OwnerUserId
JOIN PostTypes PT ON P.PostTypeId = PT.Id
WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
ORDER BY TU.Reputation DESC, TU.TotalViews DESC;