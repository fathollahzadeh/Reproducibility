WITH PostMetrics AS (
    SELECT 
        P.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.PostTypeId
),
UserMetrics AS (
    SELECT 
        U.Reputation,
        COUNT(DISTINCT U.Id) AS TotalUsers,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes
    FROM 
        Users U
    GROUP BY 
        U.Reputation
),
VoteMetrics AS (
    SELECT 
        V.VoteTypeId,
        COUNT(*) AS TotalVotes
    FROM 
        Votes V
    GROUP BY 
        V.VoteTypeId
)

SELECT 
    PM.PostTypeId,
    PM.TotalPosts,
    PM.AcceptedAnswers,
    PM.TotalScore,
    PM.TotalViews,
    UM.TotalUsers,
    UM.TotalUpVotes,
    UM.TotalDownVotes,
    VM.VoteTypeId,
    VM.TotalVotes
FROM 
    PostMetrics PM
CROSS JOIN 
    UserMetrics UM
CROSS JOIN 
    VoteMetrics VM
ORDER BY 
    PM.PostTypeId, VM.VoteTypeId;