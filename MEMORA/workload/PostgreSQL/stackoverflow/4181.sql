
WITH PopularPosts AS (
    SELECT 
        P.Id,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8  
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND P.Score > 10
    GROUP BY 
        P.Id, P.Title
),
RecentUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        MAX(U.CreationDate) AS RecentDate
    FROM 
        Users U
    WHERE 
        U.Reputation < 100
    GROUP BY 
        U.Id, U.DisplayName
),
TopTags AS (
    SELECT 
        T.TagName,
        T.Count
    FROM 
        Tags T
    WHERE 
        T.Count > 50
    ORDER BY 
        T.Count DESC
    LIMIT 5
)
SELECT 
    PP.Title,
    PP.CommentCount,
    PP.TotalBounty,
    RU.DisplayName AS RecentUser,
    TT.TagName
FROM 
    PopularPosts PP
JOIN 
    RecentUsers RU ON RU.RecentDate = (SELECT MAX(RecentDate) FROM RecentUsers)
CROSS JOIN 
    TopTags TT
WHERE 
    PP.CommentCount > 3
ORDER BY 
    PP.TotalBounty DESC
LIMIT 10;
