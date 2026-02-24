WITH UserTags AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName AS UserDisplayName,
        COUNT(DISTINCT T.Id) AS TagCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagNames
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN TAGS T ON POSITION(T.TagName IN P.Tags) > 0
    GROUP BY U.Id, U.DisplayName
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        MAX(B.Date) AS LastBadgeDate
    FROM Badges B
    GROUP BY B.UserId
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
FinalReport AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName AS UserDisplayName,
        COALESCE(UT.TagCount, 0) AS TagCount,
        COALESCE(UT.TagNames, 'None') AS TagNames,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(UB.BadgeNames, 'None') AS BadgeNames,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.AverageScore, 0) AS AverageScore
    FROM Users U
    LEFT JOIN UserTags UT ON U.Id = UT.UserId
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UserId,
    UserDisplayName,
    TagCount,
    TagNames,
    BadgeCount,
    BadgeNames,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews,
    AverageScore
FROM FinalReport
WHERE PostCount > 0
ORDER BY PostCount DESC, AverageScore DESC
LIMIT 10;
