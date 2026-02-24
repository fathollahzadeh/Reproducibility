WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostsCount,
        COUNT(DISTINCT C.Id) AS CommentsCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        PostsCount,
        CommentsCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserVoteStats
), RecentPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS RecentPosts,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    WHERE 
        P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        P.OwnerUserId
)

SELECT 
    R.DisplayName,
    R.Reputation,
    R.UpVotes,
    R.DownVotes,
    R.PostsCount,
    R.CommentsCount,
    COALESCE(RP.RecentPosts, 0) AS RecentPosts,
    RP.LastPostDate
FROM 
    RankedUsers R
LEFT JOIN 
    RecentPostStats RP ON R.UserId = RP.OwnerUserId
WHERE 
    (R.UpVotes - R.DownVotes) > 10
    AND R.Rank <= 100
ORDER BY 
    R.Rank;