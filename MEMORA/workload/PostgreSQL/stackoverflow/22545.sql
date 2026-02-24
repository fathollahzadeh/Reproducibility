
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (10, 11, 12) THEN 1 ELSE 0 END), 0) AS PostHistoryVotes,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views
),

PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.Score,
        P.CreationDate,
        P.ClosedDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    WHERE 
        P.ViewCount > 100
),

VoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),

RecentPostHistory AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalEdits,
        MIN(CreationDate) AS FirstEditDate,
        MAX(CreationDate) AS LastEditDate
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        PostId
)

SELECT 
    U.DisplayName,
    U.Reputation,
    U.Views,
    P.UserPostRank,
    COUNT(P.PostId) AS NumberOfPosts,
    COALESCE(VC.TotalUpVotes, 0) AS PostUpVotes,
    COALESCE(VC.TotalDownVotes, 0) AS PostDownVotes,
    PH.TotalEdits,
    PH.FirstEditDate,
    PH.LastEditDate
FROM 
    UserStatistics U
LEFT JOIN 
    PostDetails P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    VoteCounts VC ON P.PostId = VC.PostId
LEFT JOIN 
    RecentPostHistory PH ON P.PostId = PH.PostId
WHERE 
    U.Reputation > 1000 
    AND (PH.TotalEdits IS NULL OR PH.TotalEdits > 3) 
GROUP BY 
    U.DisplayName, U.Reputation, U.Views, P.UserPostRank, VC.TotalUpVotes, VC.TotalDownVotes, PH.TotalEdits, PH.FirstEditDate, PH.LastEditDate
ORDER BY 
    U.Reputation DESC, NumberOfPosts DESC
LIMIT 10;
