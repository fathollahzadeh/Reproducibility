
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
),
PostsWithTags AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Tags,
        P.OwnerUserId,
        PT.Name AS PostTypeName,
        COALESCE(PT.Name, 'Unknown') AS PostType 
    FROM 
        Posts P
    LEFT JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
),
PostVoteStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)
SELECT 
    R.DisplayName,
    R.Reputation,
    PWT.PostTypeName,
    PWT.Title,
    PWT.CreationDate,
    PWT.Tags,
    PVS.UpVotes,
    PVS.DownVotes,
    PC.LastClosedDate,
    R.ReputationRank
FROM 
    RankedUsers R
JOIN 
    PostsWithTags PWT ON R.UserId = PWT.OwnerUserId
LEFT JOIN 
    PostVoteStats PVS ON PWT.PostId = PVS.PostId
LEFT JOIN 
    ClosedPosts PC ON PWT.PostId = PC.PostId
WHERE 
    PC.LastClosedDate IS NULL 
    OR PC.LastClosedDate < CURRENT_DATE - INTERVAL '1 year'
ORDER BY 
    R.Reputation DESC, 
    PVS.UpVotes DESC
LIMIT 100 OFFSET 0;
