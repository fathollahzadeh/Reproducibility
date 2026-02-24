WITH RECURSIVE UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId IN (4,5) THEN 1 ELSE 0 END) AS WikiCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
),
RecentVotes AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    WHERE V.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY V.UserId
),
UsersWithBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
FinalSummary AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(UPC.PostCount, 0) AS TotalPosts,
        COALESCE(UPC.QuestionCount, 0) AS TotalQuestions,
        COALESCE(UPC.AnswerCount, 0) AS TotalAnswers,
        COALESCE(UPC.WikiCount, 0) AS TotalWikis,
        COALESCE(RV.VoteCount, 0) AS TotalVotes,
        COALESCE(RV.UpVotes, 0) AS TotalUpVotes,
        COALESCE(RV.DownVotes, 0) AS TotalDownVotes,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        COALESCE(UB.HighestBadgeClass, 0) AS HighestBadge
    FROM Users U
    LEFT JOIN UserPostCounts UPC ON U.Id = UPC.UserId
    LEFT JOIN RecentVotes RV ON U.Id = RV.UserId
    LEFT JOIN UsersWithBadges UB ON U.Id = UB.UserId
)
SELECT 
    FS.UserId,
    FS.TotalPosts,
    FS.TotalQuestions,
    FS.TotalAnswers,
    FS.TotalWikis,
    FS.TotalVotes,
    FS.TotalUpVotes,
    FS.TotalDownVotes,
    FS.TotalBadges,
    FS.HighestBadge
FROM FinalSummary FS
WHERE FS.TotalPosts > 0
    AND FS.TotalBadges > 0
ORDER BY FS.TotalVotes DESC NULLS LAST
LIMIT 50;