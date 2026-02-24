WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8
    WHERE U.Reputation > 100
    GROUP BY U.Id, U.DisplayName
),

RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        TotalViews,
        AnswerCount,
        TotalBounty,
        RANK() OVER (ORDER BY TotalViews DESC, QuestionCount DESC) AS ViewRank
    FROM UserActivity
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        TotalViews,
        AnswerCount,
        TotalBounty
    FROM RankedUsers
    WHERE ViewRank <= 10
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.QuestionCount,
    U.TotalViews,
    U.AnswerCount,
    COALESCE(B.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN U.AnswerCount > 5 THEN 'Answer Enthusiast' 
        ELSE 'New Contributor' 
    END AS UserCategory
FROM TopUsers U
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
) B ON U.UserId = B.UserId
ORDER BY U.TotalViews DESC;
