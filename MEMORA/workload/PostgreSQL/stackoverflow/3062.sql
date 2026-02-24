WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.UpVotes,
        U.DownVotes,
        Row_Number() OVER (PARTITION BY U.Id ORDER BY U.CreationDate DESC) AS RecentActivity
    FROM Users U
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),
TopUsers AS (
    SELECT 
        UR.UserId, 
        UR.DisplayName, 
        COALESCE(PS.TotalQuestions, 0) AS Questions, 
        COALESCE(PS.TotalAnswers, 0) AS Answers,
        UR.Reputation,
        ROW_NUMBER() OVER (ORDER BY COALESCE(PS.TotalQuestions, 0) DESC, COALESCE(PS.TotalAnswers, 0) DESC) AS UserRank
    FROM UserReputation UR
    LEFT JOIN PostStats PS ON UR.UserId = PS.OwnerUserId
    WHERE UR.Reputation > 1000
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
),
FinalUserStats AS (
    SELECT 
        TU.UserId,
        TU.DisplayName,
        TU.Questions,
        TU.Answers,
        TU.Reputation,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        COALESCE(UB.BadgeNames, 'No Badges') AS Badges
    FROM TopUsers TU
    LEFT JOIN UserBadges UB ON TU.UserId = UB.UserId
    WHERE TU.UserRank <= 10
)
SELECT
    FUS.DisplayName,
    FUS.Questions,
    FUS.Answers,
    FUS.Reputation,
    FUS.TotalBadges,
    FUS.Badges,
    CASE 
        WHEN FUS.TotalBadges > 5 THEN 'Highly Recognized'
        WHEN FUS.TotalBadges BETWEEN 1 AND 5 THEN 'Moderately Recognized'
        ELSE 'New User'
    END AS RecognitionLevel
FROM FinalUserStats FUS
ORDER BY FUS.Reputation DESC, FUS.Questions DESC;
