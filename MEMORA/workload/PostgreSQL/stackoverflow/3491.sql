
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        COALESCE(COUNT(CM.Id), 0) AS CommentCount,
        P.ViewCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments CM ON P.Id = CM.PostId
    WHERE 
        P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerUserId, P.Score, P.ViewCount
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        UpVotes,
        DownVotes
    FROM 
        UserStats
    WHERE 
        ActivityRank <= 10
),
UserPostStats AS (
    SELECT 
        AU.UserId,
        AU.DisplayName,
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.CommentCount,
        RP.ViewCount
    FROM 
        ActiveUsers AU
    JOIN 
        RecentPosts RP ON AU.UserId = RP.OwnerUserId
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    U.BadgeCount,
    U.UpVotes,
    U.DownVotes,
    P.Title AS RecentPostTitle,
    P.CreationDate AS PostCreationDate,
    P.Score,
    P.CommentCount,
    P.ViewCount
FROM 
    UserPostStats P
JOIN 
    ActiveUsers U ON P.UserId = U.UserId
ORDER BY 
    U.Reputation DESC, P.CreationDate DESC;
