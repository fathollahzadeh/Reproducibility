WITH RECURSIVE PostScoreCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Score AS PostScore,
        P.OwnerUserId,
        P.CreationDate,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Score, P.OwnerUserId, P.CreationDate
),
UserReputationCTE AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(PS.PostScore, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostScoreCTE PS ON P.Id = PS.PostId
    GROUP BY 
        U.Id, U.Reputation
),
TopBadgedUsers AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    WHERE 
        B.Class = 1 
    GROUP BY 
        B.UserId
    HAVING 
        COUNT(B.Id) > 2
),
PostsWithComments AS (
    SELECT 
        P.Id AS PostId,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    UR.TotalPosts,
    UR.TotalScore,
    COALESCE(TB.BadgeCount, 0) AS GoldBadgeCount,
    COALESCE(PC.CommentCount, 0) AS CommentCount,
    (UR.TotalScore / NULLIF(UR.TotalPosts, 0)) AS AvgScorePerPost,
    RANK() OVER (ORDER BY UR.TotalScore DESC) AS UserRank
FROM 
    Users U
LEFT JOIN 
    UserReputationCTE UR ON U.Id = UR.UserId
LEFT JOIN 
    TopBadgedUsers TB ON U.Id = TB.UserId
LEFT JOIN 
    PostsWithComments PC ON U.Id = PC.PostId
WHERE 
    U.Reputation > 100 
ORDER BY 
    AvgScorePerPost DESC
LIMIT 50;