WITH RecursiveTopUsers AS (
    SELECT 
        U.Id, 
        U.DisplayName, 
        U.Reputation, 
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
),
TopPostTypes AS (
    SELECT 
        P.PostTypeId, 
        COUNT(*) AS PostCount
    FROM 
        Posts P
    GROUP BY 
        P.PostTypeId
    HAVING 
        COUNT(*) > 100
),
RecentPostHistory AS (
    SELECT 
        PH.PostId, 
        PH.PostHistoryTypeId, 
        PH.CreationDate, 
        PH.UserId, 
        U.DisplayName AS EditorName
    FROM 
        PostHistory PH
    JOIN 
        Users U ON PH.UserId = U.Id
    WHERE 
        PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation AS UserReputation,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosedPosts,
    SUM(CASE WHEN PH.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS TotalDeletedPosts,
    COUNT(DISTINCT PH.PostId) AS UniquePostHistoryEntries,
    AVG(P.Score) AS AveragePostScore
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    RecentPostHistory PH ON P.Id = PH.PostId
WHERE 
    U.Reputation IS NOT NULL
    AND U.Id IN (SELECT Id FROM RecursiveTopUsers WHERE UserRank <= 10)
    AND EXISTS (SELECT 1 FROM TopPostTypes TPT WHERE P.PostTypeId = TPT.PostTypeId)
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    TotalPosts DESC, UserReputation DESC
LIMIT 20;