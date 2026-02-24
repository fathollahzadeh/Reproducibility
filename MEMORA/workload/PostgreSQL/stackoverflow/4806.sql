
WITH RankedUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    WHERE U.Reputation > 1000
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        AVG(V.VoteTypeId) AS AverageVoteType,
        P.OwnerUserId,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Accepted' 
            ELSE 'Not Accepted' 
        END AS AcceptanceStatus
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2 
    GROUP BY P.Id, P.Title, P.OwnerUserId, P.AcceptedAnswerId
),
PostWithOwner AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CommentCount,
        PS.AverageVoteType,
        U.DisplayName AS OwnerDisplayName,
        PS.AcceptanceStatus,
        PS.OwnerUserId
    FROM PostSummary PS
    JOIN Users U ON PS.OwnerUserId = U.Id
)
SELECT 
    PWO.OwnerDisplayName,
    PWO.Title,
    PWO.CommentCount,
    PWO.AcceptanceStatus,
    RU.UserRank,
    CASE 
        WHEN PWO.CommentCount > 10 THEN 'Highly Engaged'
        ELSE 'Less Engaged'
    END AS EngagementLevel
FROM PostWithOwner PWO
LEFT JOIN RankedUsers RU ON PWO.OwnerUserId = RU.Id
WHERE RU.UserRank IS NOT NULL
ORDER BY RU.UserRank, PWO.CommentCount DESC;
