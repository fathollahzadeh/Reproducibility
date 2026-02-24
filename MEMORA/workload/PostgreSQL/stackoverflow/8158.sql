WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
TopTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
UserRankings AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        UpVotes,
        DownVotes,
        TotalViews,
        RANK() OVER (ORDER BY TotalPosts DESC, UpVotes DESC) AS PostRank
    FROM 
        UserActivity
)
SELECT 
    UR.DisplayName,
    UR.TotalPosts,
    UR.TotalComments,
    UR.UpVotes,
    UR.DownVotes,
    UR.TotalViews,
    TT.TagName
FROM 
    UserRankings UR
JOIN 
    TopTags TT ON UR.TotalPosts > 0
ORDER BY 
    UR.PostRank, UR.DisplayName;
