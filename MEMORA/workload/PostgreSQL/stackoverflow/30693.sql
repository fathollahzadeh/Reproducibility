WITH RECURSIVE UserBadgeCounts AS (
    SELECT
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStats AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),
ClosedPostReasons AS (
    SELECT
        PH.UserId,
        COUNT(*) AS TotalClosedPosts,
        STRING_AGG(CASE
            WHEN PHT.Name = 'Post Closed' THEN 'Closed' 
            WHEN PHT.Name = 'Post Reopened' THEN 'Reopened' 
            ELSE 'Other'
        END, ', ') AS ClosureDetails
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY PH.UserId
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(BadgeCount, 0) AS BadgeCount,
        COALESCE(TotalPosts, 0) AS TotalPosts,
        COALESCE(TotalClosedPosts, 0) AS TotalClosedPosts,
        COALESCE(ClosureDetails, 'None') AS ClosureDetails
    FROM Users U
    LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN ClosedPostReasons CPR ON U.Id = CPR.UserId
)
SELECT 
    AU.UserId,
    AU.DisplayName,
    AU.BadgeCount,
    AU.TotalPosts,
    AU.TotalClosedPosts,
    AU.ClosureDetails
FROM ActiveUsers AU
WHERE 
    AU.BadgeCount > 0 
    OR AU.TotalPosts > 5 
    OR AU.TotalClosedPosts > 3
ORDER BY AU.BadgeCount DESC, AU.TotalPosts DESC;