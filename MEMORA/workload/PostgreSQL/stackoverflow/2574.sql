
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS PostCount, 
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)
    WHERE 
        U.CreationDate >= '2020-01-01'
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
RankedUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        TotalBounties,
        RANK() OVER (ORDER BY PostCount DESC, TotalBounties DESC) AS UserRank
    FROM 
        UserActivity
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        TotalBounties
    FROM 
        RankedUsers
    WHERE 
        UserRank <= 10
)
SELECT 
    TU.DisplayName,
    TU.PostCount,
    TU.TotalBounties,
    (SELECT COUNT(*) FROM Votes V WHERE V.UserId = TU.UserId AND V.VoteTypeId = 2) AS UpVotesReceived,
    (SELECT COUNT(*) FROM Votes V WHERE V.UserId = TU.UserId AND V.VoteTypeId = 3) AS DownVotesReceived
FROM 
    TopUsers TU
LEFT JOIN 
    Badges B ON TU.UserId = B.UserId
WHERE 
    B.Class = 1 OR B.Class = 2
GROUP BY 
    TU.UserId, TU.DisplayName, TU.PostCount, TU.TotalBounties
ORDER BY 
    TU.PostCount DESC, TU.TotalBounties DESC;
