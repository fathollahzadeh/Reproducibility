
WITH RECURSIVE RecursiveUserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        0 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000  

    UNION ALL

    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        R.Level + 1
    FROM 
        Users U
    INNER JOIN RecursiveUserStats R ON U.Id = R.UserId
    WHERE 
        U.Reputation < R.Reputation  
),

RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        U.DisplayName AS Author,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'  
    GROUP BY 
        P.Id, U.DisplayName
),

TopTagPosts AS (
    SELECT 
        T.TagName,
        P.Title,
        P.Score,
        P.CreationDate,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName, P.Title, P.Score, P.CreationDate
    ORDER BY 
        PostCount DESC
    LIMIT 10
)

SELECT 
    RUS.UserId,
    RUS.DisplayName,
    RUS.Reputation,
    RUS.Views,
    RUS.UpVotes,
    RUS.DownVotes,
    RP.PostId,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostCreationDate,
    RP.CommentCount,
    RP.UpVotes AS RecentPostUpVotes,
    RP.DownVotes AS RecentPostDownVotes,
    TTP.TagName,
    TTP.PostCount AS TopPostCount
FROM 
    RecursiveUserStats RUS
LEFT JOIN 
    RecentPosts RP ON RP.Author = RUS.DisplayName
LEFT JOIN 
    TopTagPosts TTP ON TTP.Title = RP.Title
WHERE 
    (RP.CommentCount > 5 OR RUS.Reputation > 2000)  
AND 
    RP.CreationDate IS NOT NULL
ORDER BY 
    RUS.Reputation DESC, RP.Score DESC
LIMIT 100;
