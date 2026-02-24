WITH RankedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        P.CreationDate,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownVoteCount,
        COALESCE(B.UserId, -1) AS BadgeOwnerId
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId AND B.Class = 1
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        RP.Id,
        RP.Title,
        RP.Score,
        RP.OwnerUserId,
        RP.PostRank
    FROM 
        RankedPosts RP
    WHERE 
        RP.PostRank <= 3
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(RP.UpVoteCount) AS TotalUpVotes,
        SUM(RP.DownVoteCount) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        RankedPosts RP ON P.Id = RP.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)
SELECT 
    US.DisplayName,
    US.Reputation,
    US.PostCount,
    US.TotalUpVotes,
    US.TotalDownVotes,
    TP.Title AS TopPostTitle,
    TP.Score AS TopPostScore,
    COALESCE(PH.Name, 'No Badge') AS BadgeName
FROM 
    UserStats US
LEFT JOIN 
    TopPosts TP ON US.UserId = TP.OwnerUserId
LEFT JOIN 
    Badges B ON US.UserId = B.UserId 
LEFT JOIN 
    PostHistoryTypes PH ON B.Class = PH.Id
WHERE 
    US.Reputation > 1000
ORDER BY 
    US.TotalUpVotes DESC, US.PostCount DESC;