
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(COUNT(Cm.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Comments Cm ON P.Id = Cm.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score
),
UserPostDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        US.UpVotes AS UserUpVotes,
        US.DownVotes AS UserDownVotes,
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Score,
        PS.CommentCount,
        PS.UpVotes AS PostUpVotes,
        PS.DownVotes AS PostDownVotes
    FROM 
        Users U
    JOIN 
        UserStatistics US ON U.Id = US.UserId
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    UserUpVotes,
    UserDownVotes,
    PostId,
    Title,
    CreationDate,
    Score,
    CommentCount,
    PostUpVotes,
    PostDownVotes
FROM 
    UserPostDetails
ORDER BY 
    Reputation DESC, UserId;
