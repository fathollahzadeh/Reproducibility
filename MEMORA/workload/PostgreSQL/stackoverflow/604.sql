
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
), RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
), PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        UV.UpVotes,
        UV.DownVotes
    FROM 
        RecentPosts RP
    LEFT JOIN 
        Users U ON RP.AcceptedAnswerId = U.Id
    LEFT JOIN 
        UserVoteCounts UV ON U.Id = UV.UserId
    WHERE 
        RP.rn = 1
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.Score,
    PD.ViewCount,
    PD.OwnerDisplayName,
    COALESCE(PH.UserDisplayName, 'Unknown') AS LastEditor,
    PH.CreationDate AS LastEditDate,
    PD.UpVotes,
    PD.DownVotes,
    (PD.UpVotes - PD.DownVotes) AS VoteNet
FROM 
    PostDetails PD
LEFT JOIN 
    PostHistory PH ON PD.PostId = PH.PostId AND PH.PostHistoryTypeId IN (4, 5)  
WHERE 
    PD.Score > 0 
ORDER BY 
    VoteNet DESC, PD.CreationDate DESC
LIMIT 10;
