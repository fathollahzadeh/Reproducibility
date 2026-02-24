WITH UserVotes AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        P.CreationDate,
        EXTRACT(YEAR FROM P.CreationDate) AS CreationYear,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(COALESCE(GREATEST(V.BountyAmount, 0), 0)) AS TotalBountyAmount,
        DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId, P.AcceptedAnswerId, P.CreationDate
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        PH.UserId,
        CASE 
            WHEN PH.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN PH.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Other Changes' 
        END AS ChangeType
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 year')
),
RelevantPosts AS (
    SELECT 
        PA.PostId,
        PA.Title,
        PA.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COALESCE(UP.TotalVotes, 0) AS UserTotalVotes,
        COALESCE(UP.UpVotes, 0) AS UserUpVotes,
        COALESCE(UP.DownVotes, 0) AS UserDownVotes,
        PHD.ChangeType,
        ROW_NUMBER() OVER (PARTITION BY PA.PostId ORDER BY PHD.CreationDate DESC) AS ChangeRank
    FROM 
        PostAnalytics PA
    JOIN 
        Users U ON PA.OwnerUserId = U.Id
    LEFT JOIN 
        UserVotes UP ON U.Id = UP.UserId
    LEFT JOIN 
        PostHistoryDetails PHD ON PA.PostId = PHD.PostId
    WHERE 
        PA.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '2 years')
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.OwnerDisplayName,
    RP.UserTotalVotes,
    RP.UserUpVotes,
    RP.UserDownVotes,
    RP.ChangeType,
    CASE 
        WHEN RP.ChangeType = 'Closed' THEN 'Post is closed.'
        WHEN RP.ChangeType = 'Reopened' THEN 'Post has been reopened.'
        ELSE 'No closure activity.'
    END AS ClosureStatus,
    RANK() OVER (ORDER BY RP.UserTotalVotes DESC) AS PopularityRank
FROM 
    RelevantPosts RP
WHERE 
    RP.ChangeRank = 1 
    AND RP.UserTotalVotes IS NOT NULL
ORDER BY 
    PopularityRank, RP.CreationDate DESC;