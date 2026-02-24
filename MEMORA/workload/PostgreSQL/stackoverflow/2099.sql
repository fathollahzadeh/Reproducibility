
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes,
        COALESCE(SUM(B.Class), 0) AS TotalBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalViews,
        PostCount,
        CommentCount,
        NetVotes,
        TotalBadges,
        RANK() OVER (ORDER BY TotalViews DESC) AS RankByViews,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPosts
    FROM UserActivity
),
AggregateStats AS (
    SELECT 
        AVG(TotalViews) AS AvgViews,
        AVG(PostCount) AS AvgPosts,
        AVG(CommentCount) AS AvgComments,
        AVG(NetVotes) AS AvgNetVotes,
        AVG(TotalBadges) AS AvgBadges
    FROM TopUsers
)
SELECT 
    T.DisplayName,
    T.TotalViews,
    T.PostCount,
    T.CommentCount,
    T.NetVotes,
    T.TotalBadges,
    T.RankByViews,
    T.RankByPosts,
    A.AvgViews,
    A.AvgPosts,
    A.AvgComments,
    A.AvgNetVotes,
    A.AvgBadges,
    CASE 
        WHEN T.TotalViews > A.AvgViews THEN 'Above Average'
        WHEN T.TotalViews < A.AvgViews THEN 'Below Average'
        ELSE 'Average' 
    END AS ViewStatus,
    CASE 
        WHEN T.PostCount > A.AvgPosts THEN 'Above Average'
        WHEN T.PostCount < A.AvgPosts THEN 'Below Average'
        ELSE 'Average' 
    END AS PostStatus
FROM TopUsers T
CROSS JOIN AggregateStats A
WHERE T.NetVotes > 0
ORDER BY T.TotalViews DESC, T.PostCount DESC;
