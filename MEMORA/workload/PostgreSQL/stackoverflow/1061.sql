WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 100
    GROUP BY U.Id, U.DisplayName
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(C.Comments) AS CommentCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN (SELECT PostId, COUNT(*) AS Comments FROM Comments GROUP BY PostId) C ON P.Id = C.PostId
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.Id, P.Title
),
RankedPosts AS (
    SELECT 
        PE.PostId,
        PE.Title,
        PE.UpVotes,
        PE.DownVotes,
        PE.CommentCount,
        RANK() OVER (ORDER BY PE.UpVotes DESC) AS VoteRank
    FROM PostEngagement PE
)

SELECT 
    UPS.DisplayName,
    UPS.PostCount,
    UPS.QuestionCount,
    UPS.AnswerCount,
    UPS.TotalViews,
    UPS.AvgScore,
    RP.Title,
    RP.UpVotes,
    RP.DownVotes,
    RP.CommentCount,
    RP.VoteRank
FROM UserPostStats UPS
LEFT JOIN RankedPosts RP ON UPS.UserId = RP.PostId
WHERE UPS.PostCount > 10
ORDER BY UPS.AvgScore DESC, RP.VoteRank ASC
LIMIT 10;