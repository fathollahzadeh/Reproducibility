
WITH RECURSIVE UserScore AS (
    SELECT 
        U.Id, 
        U.DisplayName, 
        U.Reputation, 
        U.Views,
        U.UpVotes,
        U.DownVotes,
        0 AS Rank
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
    
    UNION ALL

    SELECT 
        U.Id, 
        U.DisplayName, 
        U.Reputation, 
        U.Views,
        U.UpVotes,
        U.DownVotes,
        US.Rank + 1
    FROM 
        Users U
    INNER JOIN UserScore US ON U.Reputation BETWEEN US.Reputation AND US.Reputation + 1000 
    WHERE 
        U.Id NOT IN (SELECT Id FROM UserScore)
),
CtePostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        MAX(P.CreationDate) AS MostRecentActivity,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY COUNT(C.Id) DESC) AS UserPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        PS.PostId,
        PS.OwnerUserId,
        PS.CommentCount,
        PS.UpVotes,
        PS.DownVotes,
        US.DisplayName AS OwnerDisplayName,
        PS.MostRecentActivity
    FROM 
        CtePostStatistics PS
    JOIN 
        Users US ON PS.OwnerUserId = US.Id
    WHERE 
        US.Reputation > 1000 AND PS.UserPostRank <= 5
)
SELECT 
    FP.OwnerDisplayName,
    SUM(FP.CommentCount) AS TotalComments,
    SUM(FP.UpVotes) AS TotalUpVotes,
    SUM(FP.DownVotes) AS TotalDownVotes,
    COUNT(FP.PostId) AS PostCount,
    AVG(FP.CommentCount) AS AvgCommentsPerPost,
    CASE 
        WHEN SUM(FP.UpVotes) > SUM(FP.DownVotes) THEN 'Positive'
        WHEN SUM(FP.UpVotes) < SUM(FP.DownVotes) THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    FilteredPosts FP
GROUP BY 
    FP.OwnerDisplayName
ORDER BY 
    TotalComments DESC
LIMIT 10;
