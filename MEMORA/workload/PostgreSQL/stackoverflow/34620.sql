WITH RECURSIVE UserPostCounts AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
), 
TopUsers AS (
    SELECT 
        UserId, 
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM 
        UserPostCounts
), 
RecentEdits AS (
    SELECT 
        PH.UserId, 
        PH.PostId, 
        PH.CreationDate, 
        PH.Comment, 
        PH.PostHistoryTypeId
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
        AND PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
), 
AggregateEdits AS (
    SELECT 
        RE.UserId,
        COUNT(RE.PostId) AS EditCount,
        STRING_AGG(DISTINCT P.Title, ', ') AS EditedPosts
    FROM 
        RecentEdits RE
    JOIN 
        Posts P ON RE.PostId = P.Id
    GROUP BY 
        RE.UserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    UC.PostCount,
    AU.EditCount,
    AU.EditedPosts
FROM 
    Users U
LEFT JOIN 
    UserPostCounts UC ON U.Id = UC.UserId
LEFT JOIN 
    AggregateEdits AU ON U.Id = AU.UserId
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC,
    AU.EditCount DESC NULLS LAST
LIMIT 10;