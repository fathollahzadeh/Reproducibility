
WITH RECURSIVE UserPostCount AS (
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

RecentEdits AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS EditRank
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5) 
),

TopContributors AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        UPC.PostCount,
        COUNT(RE.PostId) AS RecentEditCount
    FROM 
        Users U
    JOIN 
        UserPostCount UPC ON U.Id = UPC.UserId
    LEFT JOIN 
        RecentEdits RE ON U.Id = RE.UserId
    WHERE 
        U.Reputation > 1000 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, UPC.PostCount
    HAVING 
        COUNT(RE.PostId) > 5 
),

MostViewedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.ViewCount,
        RANK() OVER (ORDER BY P.ViewCount DESC) AS ViewRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '6 months') 
)

SELECT 
    U.DisplayName AS Contributor,
    U.Reputation,
    U.PostCount AS TotalPosts,
    U.RecentEditCount AS RecentEdits,
    P.Title AS MostViewedPost,
    P.ViewCount
FROM 
    TopContributors U
LEFT JOIN 
    MostViewedPosts P ON U.PostCount > 0
WHERE 
    P.ViewRank <= 10 
ORDER BY 
    U.Reputation DESC, TotalPosts DESC
LIMIT 50;
