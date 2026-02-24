
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        T.TagName
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.PostCount,
    US.CommentCount,
    US.UpVotes,
    US.DownVotes,
    PD.PostId,
    PD.Title,
    PD.CreationDate AS PostCreationDate,
    PD.Score,
    PD.ViewCount,
    STRING_AGG(DISTINCT PD.TagName, ', ') AS Tags
FROM 
    UserStats US
JOIN 
    PostDetails PD ON US.UserId = PD.PostId
GROUP BY 
    US.UserId, US.DisplayName, US.Reputation, US.PostCount, US.CommentCount, US.UpVotes, US.DownVotes, PD.PostId, PD.Title, PD.CreationDate, PD.Score, PD.ViewCount
ORDER BY 
    US.Reputation DESC, US.PostCount DESC, US.UpVotes DESC;
