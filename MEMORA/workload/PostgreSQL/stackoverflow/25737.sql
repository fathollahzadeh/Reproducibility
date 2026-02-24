
WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        COUNT(C) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.OwnerUserId, P.PostTypeId
),
TopUsersByPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(PM.UpVoteCount), 0) AS TotalUpVotes,
        COALESCE(SUM(PM.DownVoteCount), 0) AS TotalDownVotes,
        COALESCE(SUM(PM.CommentCount), 0) AS TotalComments,
        COALESCE(SUM(PM.TotalBounty), 0) AS TotalBountyEarned
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN PostMetrics PM ON P.Id = PM.PostId
    GROUP BY U.Id, U.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalUpVotes,
        TotalDownVotes,
        TotalComments,
        TotalBountyEarned,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, TotalUpVotes DESC) AS UserRank
    FROM TopUsersByPosts
)
SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.PostCount,
    RU.QuestionCount,
    RU.AnswerCount,
    RU.TotalUpVotes,
    RU.TotalDownVotes,
    RU.TotalComments,
    RU.TotalBountyEarned,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges
FROM RankedUsers RU
LEFT JOIN UserBadgeCounts UB ON RU.UserId = UB.UserId
WHERE RU.UserRank <= 10
ORDER BY RU.UserRank;
