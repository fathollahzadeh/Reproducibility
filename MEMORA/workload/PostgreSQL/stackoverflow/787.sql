WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes,
        SUM(P.Score) AS TotalScore,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
TopUsers AS (
    SELECT 
        *
    FROM 
        UserStatistics 
    WHERE 
        UserRank <= 10
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate AS PostCreationDate,
        P.Score AS PostScore,
        ARRAY_AGG(T.TagName) AS PostTags
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment,
        PH.PostHistoryTypeId,
        P.Title
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '30 days')
)
SELECT 
    U.DisplayName AS TopUser,
    U.Reputation,
    P.Title AS PostTitle,
    D.PostScore,
    D.PostTags,
    RP.Comment AS RecentChangeComment,
    RP.CreationDate AS ChangeDate
FROM 
    TopUsers U
JOIN 
    Posts P ON U.UserId = P.OwnerUserId
JOIN 
    PostDetails D ON P.Id = D.PostId
LEFT JOIN 
    RecentPostHistory RP ON P.Id = RP.PostId
ORDER BY 
    U.Reputation DESC, D.PostScore DESC;