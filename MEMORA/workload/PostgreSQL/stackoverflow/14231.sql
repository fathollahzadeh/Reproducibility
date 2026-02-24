WITH PostStats AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore,
        COUNT(DISTINCT OwnerUserId) AS UniquePostOwners
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AverageReputation,
        SUM(UpVotes + DownVotes) AS TotalVotes
    FROM 
        Users
),
VoteStats AS (
    SELECT 
        VoteTypeId,
        COUNT(*) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        VoteTypeId
)
SELECT 
    PS.PostTypeId,
    PS.PostCount,
    PS.TotalViews,
    PS.AverageScore,
    PS.UniquePostOwners,
    US.TotalUsers,
    US.AverageReputation,
    US.TotalVotes,
    VS.VoteTypeId,
    VS.VoteCount
FROM 
    PostStats PS
CROSS JOIN 
    UserStats US
JOIN 
    VoteStats VS ON VS.VoteTypeId IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 15, 16)
ORDER BY 
    PS.PostTypeId, VS.VoteTypeId;