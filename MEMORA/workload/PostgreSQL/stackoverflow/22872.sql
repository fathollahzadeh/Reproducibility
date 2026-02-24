WITH UserScoreStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(COALESCE(P.Score, 0)) AS AverageScore,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) 
                           - COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS Ranking
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        UpVoteCount, 
        DownVoteCount, 
        PostCount, 
        AverageScore,
        Ranking
    FROM 
        UserScoreStats
    WHERE 
        Ranking <= 10
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON U.Id = P.OwnerUserId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS CloseDate,
        PH.Comment AS CloseReason,
        P.Title,
        U.DisplayName AS ClosedBy
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    LEFT JOIN 
        Users U ON U.Id = PH.UserId
),
UserPostInteraction AS (
    SELECT 
        U.DisplayName AS UserName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT COALESCE(V.Id, -1)) AS TotalVotes, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.DisplayName
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.UpVoteCount,
    TU.DownVoteCount,
    TU.PostCount,
    R.PostId AS RecentPostId,
    R.Title AS RecentPostTitle,
    R.CreationDate AS RecentPostDate,
    R.OwnerDisplayName AS RecentPostOwner,
    CP.CloseDate,
    CP.CloseReason,
    CP.ClosedBy,
    UP.TotalPosts,
    UP.TotalVotes,
    UP.UpVotes,
    UP.DownVotes
FROM 
    TopUsers TU
LEFT JOIN 
    RecentPosts R ON R.OwnerDisplayName = TU.DisplayName
LEFT JOIN 
    ClosedPosts CP ON CP.Title = R.Title
LEFT JOIN 
    UserPostInteraction UP ON UP.UserName = TU.DisplayName
ORDER BY 
    TU.Ranking, R.CreationDate DESC NULLS LAST, CP.CloseDate DESC NULLS LAST;