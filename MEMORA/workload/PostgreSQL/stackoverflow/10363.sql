WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
)

SELECT 
    UPC.UserId,
    UPC.DisplayName,
    UPC.Reputation,
    UPC.PostCount
FROM UserPostCounts UPC
ORDER BY UPC.Reputation DESC, UPC.PostCount DESC
LIMIT 10;