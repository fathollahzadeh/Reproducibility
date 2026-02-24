
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        DENSE_RANK() OVER (ORDER BY COALESCE(U.Reputation, 0) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        MIN(PH.CreationDate) AS FirstEntityChange,
        MAX(PH.CreationDate) AS LastEntityChange,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        STRING_AGG(DISTINCT PH.UserDisplayName, ', ') AS UsersInvolved,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate BETWEEN DATE '2024-10-01' - INTERVAL '1 year' AND DATE '2024-10-01'
    GROUP BY 
        PH.PostId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.UpVotes,
    U.DownVotes,
    PHD.PostId,
    PHD.FirstEntityChange,
    PHD.LastEntityChange,
    PHD.CloseReopenCount,
    PHD.UsersInvolved,
    PHD.HistoryCount,
    CASE 
        WHEN PHD.HistoryCount > 5 THEN 'Active Contributor'
        WHEN PHD.HistoryCount IS NULL THEN 'No Activity'
        ELSE 'Regular'
    END AS ActivityLevel,
    CASE 
        WHEN U.Reputation IS NULL THEN 'No Reputation Data'
        ELSE 
            CASE 
                WHEN U.Reputation > 1000 THEN 'High Reputation'
                WHEN U.Reputation BETWEEN 100 AND 1000 THEN 'Medium Reputation'
                ELSE 'Low Reputation'
            END 
    END AS ReputationTier
FROM 
    UserStats U
LEFT JOIN 
    PostHistoryDetails PHD ON U.UserId = PHD.PostId
WHERE 
    U.Reputation IS NOT NULL
ORDER BY 
    U.Reputation DESC, U.UserId ASC
FETCH FIRST 100 ROWS ONLY;
