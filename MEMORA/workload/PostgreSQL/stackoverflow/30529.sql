
WITH RecursiveCTE AS (
    SELECT 
        Id, 
        PostTypeId, 
        Title, 
        OwnerUserId, 
        CreationDate,
        ROW_NUMBER() OVER (PARTITION BY OwnerUserId ORDER BY CreationDate DESC) AS rn
    FROM Posts
    WHERE PostTypeId = 1 
), 
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViewCount,
        COALESCE(SUM(P.Score), 0) AS TotalScore,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        MAX(P.CreationDate) AS LastQuestionDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN Comments C ON C.UserId = U.Id
    GROUP BY U.Id, U.DisplayName
),
UserBadges AS (
    SELECT 
        B.UserId, 
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        COUNT(B.Id) AS BadgeCount
    FROM Badges B
    GROUP BY B.UserId
),
TopContributors AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalViewCount,
        UA.TotalScore,
        UA.QuestionCount,
        UA.CommentCount,
        COALESCE(UB.BadgeNames, 'No Badges') AS BadgeNames,
        ROW_NUMBER() OVER (ORDER BY UA.TotalScore DESC, UA.QuestionCount DESC) AS Rank
    FROM UserActivity UA
    LEFT JOIN UserBadges UB ON UA.UserId = UB.UserId
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.TotalViewCount,
    T.TotalScore,
    T.QuestionCount,
    T.CommentCount,
    T.BadgeNames,
    HR.Id AS PostId,
    HR.Title AS RecentQuestionTitle,
    HR.CreationDate AS RecentQuestionDate
FROM TopContributors T
LEFT JOIN RecursiveCTE HR ON T.UserId = HR.OwnerUserId AND HR.rn = 1   
WHERE T.Rank <= 10 
ORDER BY T.TotalScore DESC, T.QuestionCount DESC;
