
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
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
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PopularPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.Score,
        PD.ViewCount,
        PD.OwnerDisplayName,
        ROW_NUMBER() OVER (ORDER BY PD.Score DESC, PD.ViewCount DESC) AS Rank
    FROM 
        PostDetails PD
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.BadgeCount,
    US.TotalUpVotes,
    US.TotalDownVotes,
    PP.Title,
    PP.Score,
    PP.ViewCount,
    PP.OwnerDisplayName
FROM 
    UserStats US
JOIN 
    PopularPosts PP ON PP.Rank <= 10
ORDER BY 
    US.Reputation DESC, 
    PP.Score DESC;
