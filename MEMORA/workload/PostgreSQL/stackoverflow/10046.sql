WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN V.VoteTypeId = 5 THEN 1 ELSE 0 END) AS TotalFavorites
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 100 
    GROUP BY 
        U.Id, U.DisplayName
),
PostTypesCount AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS Count
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        PT.Name
),
MostActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        TotalFavorites,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    M.DisplayName,
    M.TotalPosts,
    M.TotalComments,
    M.TotalUpVotes,
    M.TotalDownVotes,
    M.TotalFavorites,
    PT.PostType,
    PT.Count AS PostTypeCount
FROM 
    MostActiveUsers M
JOIN 
    PostTypesCount PT ON M.TotalPosts > 0
WHERE 
    M.Rank <= 10 
ORDER BY 
    M.TotalPosts DESC, PT.PostType;