WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        UpVotes, 
        DownVotes, 
        CommentCount
    FROM 
        UserActivity
    WHERE 
        UserRank <= 10
)

SELECT 
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    COALESCE(T.UpVotes - T.DownVotes, 0) AS NetVotes,
    CASE 
        WHEN T.CommentCount > 5 THEN 'Active'
        ELSE 'Less Active'
    END AS ActivityLevel,
    ARRAY_AGG(DISTINCT P.Title) AS PostTitles,
    COUNT(DISTINCT PH.UserId) AS EditCount
FROM 
    TopUsers T
LEFT JOIN 
    Posts P ON T.UserId = P.OwnerUserId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 6)
GROUP BY 
    T.UserId, T.DisplayName, T.Reputation, T.PostCount, T.UpVotes, T.DownVotes, T.CommentCount
ORDER BY 
    T.Reputation DESC;
