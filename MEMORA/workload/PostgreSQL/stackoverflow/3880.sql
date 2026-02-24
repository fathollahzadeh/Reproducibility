WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        UpVotes,
        DownVotes,
        PostCount,
        CommentCount,
        RANK() OVER (ORDER BY (PostCount - DownVotes + UpVotes) DESC) AS UserRank
    FROM 
        UserActivity
),
PostInfo AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        C.UserDisplayName AS LastCommenter,
        P.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY C.CreationDate DESC) AS CommentRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
PostStats AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        LastCommenter,
        LastActivityDate
    FROM 
        PostInfo
    WHERE 
        CommentRank = 1
)
SELECT 
    TU.DisplayName,
    TU.UpVotes,
    TU.DownVotes,
    TU.PostCount,
    TU.CommentCount,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.LastCommenter,
    PS.LastActivityDate
FROM 
    TopUsers TU
JOIN 
    PostStats PS ON TU.UserId = PS.PostId
WHERE 
    TU.UserRank <= 10
ORDER BY 
    TU.UserRank;