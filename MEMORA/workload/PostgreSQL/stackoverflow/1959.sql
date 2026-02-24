WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        MAX(P.CreationDate) AS LastActive,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.PostCount,
    UA.Upvotes,
    UA.Downvotes,
    UA.LastActive,
    CASE 
        WHEN UA.Rank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory,
    COALESCE(NULLIF(UT.Name, ''), 'No User Type') AS UserType
FROM 
    UserActivity UA
LEFT JOIN 
    (SELECT * FROM (VALUES (1, 'Active'), (2, 'Inactive'), (3, 'Guest')) AS UT(Id, Name)) UT ON UA.Reputation / 100 > UT.Id
WHERE 
    UA.PostCount > 0 
    AND (UA.LastActive >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
ORDER BY 
    UA.Reputation DESC;