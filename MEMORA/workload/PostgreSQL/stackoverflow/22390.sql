WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COALESCE(SUM(CASE WHEN P.Score > 0 THEN P.Score ELSE 0 END), 0) AS TotalPositiveScore,
        COALESCE(SUM(CASE WHEN P.Score < 0 THEN P.Score ELSE 0 END), 0) AS TotalNegativeScore,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.Views
),
BadgesStats AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
),
PostHistories AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS EditCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6, 24)  
    GROUP BY PH.UserId, PH.PostId, PH.PostHistoryTypeId
),
UserActivity AS (
    SELECT 
        U.UserId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM (
        SELECT U.Id AS UserId
        FROM Users U
        WHERE U.Reputation > 1000
    ) AS U
    LEFT JOIN Comments C ON C.UserId = U.UserId
    LEFT JOIN Votes V ON V.UserId = U.UserId
    GROUP BY U.UserId
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.Reputation,
    UPS.Views,
    UPS.TotalPositiveScore,
    UPS.TotalNegativeScore,
    UPS.QuestionCount,
    UPS.AnswerCount,
    COALESCE(BS.GoldBadges, 0) AS GoldBadges,
    COALESCE(BS.SilverBadges, 0) AS SilverBadges,
    COALESCE(BS.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PH.EditCount, 0) AS TotalEdits,
    COALESCE(A.CommentCount, 0) AS TotalComments,
    COALESCE(A.VoteCount, 0) AS TotalVotes
FROM UserPostStats UPS
LEFT JOIN BadgesStats BS ON UPS.UserId = BS.UserId
LEFT JOIN (
    SELECT UserId, SUM(EditCount) AS EditCount
    FROM PostHistories 
    GROUP BY UserId
) PH ON UPS.UserId = PH.UserId
LEFT JOIN UserActivity A ON UPS.UserId = A.UserId
WHERE UPS.TotalPosts > 10
ORDER BY UPS.Reputation DESC, UPS.DisplayName ASC;